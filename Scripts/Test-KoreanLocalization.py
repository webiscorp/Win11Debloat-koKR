#!/usr/bin/env python3
"""Read-only ko-KR catalog gate. Python 3 standard library; no Windows mutations."""
from __future__ import annotations

import argparse
import codecs
from collections import Counter
import csv
import json
from pathlib import Path
import re
import sys
import tempfile
import unittest

CATALOG_NAMES = ("Apps", "Categories", "Chrome", "Features")
PLACEHOLDER_PATTERN = re.compile(r"\{\d+(?:,-?\d+)?(?::[^{}]*)?\}")


def unique_object(pairs):
    result = {}
    insensitive_keys = set()
    for key, value in pairs:
        if key in result or key.casefold() in insensitive_keys:
            raise ValueError(f"Duplicate or case-colliding JSON key: {key!r}")
        result[key] = value
        insensitive_keys.add(key.casefold())
    return result


def reject_constant(value):
    raise ValueError(f"Non-JSON numeric constant: {value}")


def read_strict_json(path):
    raw = path.read_bytes()
    text = raw.decode("utf-8-sig", errors="strict")
    if "\ufffd" in text or "\ufeff" in text:
        raise ValueError(f"Replacement character or embedded BOM: {path}")
    value = json.loads(text, object_pairs_hook=unique_object, parse_constant=reject_constant)
    return value, raw.startswith(codecs.BOM_UTF8)


def flatten_catalog(value, prefix):
    if not isinstance(value, dict):
        raise ValueError(f"Catalog node is not an object: {prefix}")
    result = {}
    for key, item in value.items():
        path = f"{prefix}.{key}" if prefix else key
        if isinstance(item, dict):
            result.update(flatten_catalog(item, path))
        elif isinstance(item, str) and item.strip():
            if any(ord(character) < 32 and character not in "\r\n\t" for character in item):
                raise ValueError(f"Unsupported control character: {path}")
            result[path] = item
        else:
            raise ValueError(f"Empty or non-string translation: {path}")
    return result


def format_tokens(value):
    tokens = []
    offset = 0
    while offset < len(value):
        if value[offset:offset + 2] in ("{{", "}}"):
            offset += 2
        elif value[offset] == "{":
            match = PLACEHOLDER_PATTERN.match(value, offset)
            if not match:
                raise ValueError(f"Malformed composite format near {value[offset:offset + 32]!r}")
            tokens.append(match.group())
            offset = match.end()
        elif value[offset] == "}":
            raise ValueError("Unescaped closing brace in composite format")
        else:
            offset += 1
    return Counter(tokens)


def read_reviews(repo_root):
    reviews = {}
    for path in sorted((repo_root / "docs/localization").glob("review_*.csv")):
        with path.open(encoding="utf-8-sig", newline="") as stream:
            reader = csv.DictReader(stream)
            if not {"key", "status", "reason"}.issubset(reader.fieldnames or []):
                raise ValueError(f"Review ledger has invalid columns: {path.name}")
            for row in reader:
                key = row["key"]
                if key in reviews:
                    raise ValueError(f"Review ledger repeats key: {key}")
                if row["status"] not in ("kept", "changed", "added") or not row["reason"].strip():
                    raise ValueError(f"Review ledger lacks a decision or reason: {key}")
                reviews[key] = {"status": row["status"], "reason": row["reason"], "file": path.name}
    return reviews


def validate_repository(repo_root):
    errors = []
    catalog_results = {}
    english_values = {}
    korean_values = {}
    for name in CATALOG_NAMES:
        parsed = {}
        encodings = {}
        for locale in ("en-US", "ko-KR"):
            path = repo_root / f"Config/Languages/{locale}/{name}.json"
            try:
                data, has_bom = read_strict_json(path)
                parsed[locale] = flatten_catalog(data, "" if name == "Features" else name)
                encodings[locale] = "UTF-8 with BOM" if has_bom else "UTF-8 without BOM"
            except (OSError, ValueError, UnicodeError) as error:
                errors.append(f"{locale}/{name}.json: {error}")
        if len(parsed) != 2:
            continue
        reference, translation = parsed["en-US"], parsed["ko-KR"]
        missing = sorted(reference.keys() - translation.keys())
        extra = sorted(translation.keys() - reference.keys())
        errors.extend(f"Missing Korean key: {key}" for key in missing)
        errors.extend(f"Unexpected Korean key: {key}" for key in extra)
        for key in reference.keys() & translation.keys():
            try:
                if format_tokens(reference[key]) != format_tokens(translation[key]):
                    errors.append(f"Format placeholders differ: {key}")
            except ValueError as error:
                errors.append(f"{key}: {error}")
        english_values.update(reference)
        korean_values.update(translation)
        catalog_results[name] = {"english": len(reference), "korean": len(translation),
                                 "missing": missing, "extra": extra, "encoding": encodings}

    try:
        reviews = read_reviews(repo_root)
    except (OSError, ValueError) as error:
        errors.append(str(error))
        reviews = {}
    errors.extend(f"No reviewed decision: {key}" for key in sorted(korean_values.keys() - reviews.keys()))
    errors.extend(f"Stale review key: {key}" for key in sorted(reviews.keys() - korean_values.keys()))

    try:
        allowed_values, unused_bom = read_strict_json(repo_root / "docs/localization/unchanged_english.json")
        allowed = allowed_values["entries"]
        if not isinstance(allowed, dict):
            raise ValueError("entries must be an object")
    except (OSError, ValueError, KeyError) as error:
        errors.append(f"English-equivalent classifications: {error}")
        allowed = {}
    identical = []
    identical_keys = set()
    for key in sorted(english_values.keys() & korean_values.keys()):
        if english_values[key] != korean_values[key]:
            continue
        identical_keys.add(key)
        classification = allowed.get(key, {})
        if (classification.get("english_value") != english_values[key]
                or classification.get("classification") not in ("product_name", "technical_term")
                or not classification.get("reason")):
            errors.append(f"Unclassified English-equivalent value: {key}")
        identical.append({"key": key, "value": english_values[key], **classification,
                          "review_file": reviews.get(key, {}).get("file")})
    errors.extend(f"Stale English-equivalent classification: {key}"
                  for key in sorted(allowed.keys() - identical_keys))

    return {"status": "FAIL" if errors else "PASS", "catalogs": catalog_results,
            "english_count": len(english_values), "korean_count": len(korean_values),
            "reviewed_count": len(reviews), "review_decisions": dict(Counter(r["status"] for r in reviews.values())),
            "identical_english_count": len(identical), "identical_english": identical,
            "errors": errors, "scope": "Catalog structure and recorded review coverage; no Windows execution or safety certification."}


class ValidatorRegressionTests(unittest.TestCase):
    """Negative fixtures verify corruption is rejected, independent of shipped data."""
    def test_duplicate_json_keys_fail(self):
        with self.assertRaises(ValueError):
            json.loads('{"name":"a","name":"b"}', object_pairs_hook=unique_object)
        with self.assertRaises(ValueError):
            json.loads('{"Name":"a","name":"b"}', object_pairs_hook=unique_object)

    def test_invalid_escape_fails(self):
        with self.assertRaises(ValueError):
            json.loads('{"name":"bad\\q"}', object_pairs_hook=unique_object)

    def test_utf8_bom_and_invalid_bytes(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "catalog.json"
            for prefix in (b"", codecs.BOM_UTF8):
                path.write_bytes(prefix + '{"name":"한국어"}'.encode("utf-8"))
                self.assertEqual(read_strict_json(path)[0]["name"], "한국어")
            path.write_bytes(b'{"name":"\xff"}')
            with self.assertRaises(UnicodeError):
                read_strict_json(path)

    def test_empty_and_non_string_values_fail(self):
        for value in ("", " \n ", None, 12, [], True):
            with self.assertRaises(ValueError):
                flatten_catalog({"key": value}, "Chrome")

    def test_placeholder_order_can_change_but_multiplicity_cannot(self):
        self.assertEqual(format_tokens("{0} / {1}"), format_tokens("{1} / {0}"))
        self.assertNotEqual(format_tokens("{0} {0}"), format_tokens("{0}"))
        self.assertNotEqual(format_tokens("{0:N2}"), format_tokens("{0}"))

    def test_malformed_composite_format_fails(self):
        for value in ("{0", "{name}", "{0}}", "text }"):
            with self.assertRaises(ValueError):
                format_tokens(value)
        self.assertEqual(format_tokens("{{sample}} {0}"), Counter({"{0}": 1}))

    def test_non_json_constants_fail(self):
        with self.assertRaises(ValueError):
            json.loads('{"value":NaN}', parse_constant=reject_constant)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo_root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--report", type=Path)
    parser.add_argument("--self_test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(ValidatorRegressionTests)
        if not unittest.TextTestRunner(verbosity=2).run(suite).wasSuccessful():
            return 1
    report = validate_repository(args.repo_root)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Korean catalogs {report['status']}: {report['korean_count']} strings, "
          f"{report['reviewed_count']} reviewed, {report['identical_english_count']} intentional English values")
    for error in report["errors"]:
        print(error, file=sys.stderr)
    return 1 if report["errors"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
