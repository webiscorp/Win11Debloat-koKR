<#
.SYNOPSIS
    Builds a commit-pinned Korean validation package, never a GitHub Release.
.DESCRIPTION
    Archives only committed product files. No main script or Windows changes run.
    Existing output files are not overwritten. ZIP integrity is verified after writing.
#>
[CmdletBinding()]
param(
    [string]$output_path = (Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts/korean-package')
)
$ErrorActionPreference = 'Stop'
$repo_root = Split-Path $PSScriptRoot -Parent
$product_paths = @('Win11Debloat.ps1', 'Run.bat', 'LICENSE', 'README.md', 'Scripts', 'Config', 'Schemas', 'Regfiles', 'Assets', 'docs/localization')
$output_path = [System.IO.Path]::GetFullPath($output_path)
[void][System.IO.Directory]::CreateDirectory($output_path)
$archive_path = Join-Path $output_path 'Win11Debloat.zip'
$checksums_path = Join-Path $output_path 'SHA256SUMS'
if ((Test-Path -LiteralPath $archive_path) -or (Test-Path -LiteralPath $checksums_path)) {
    throw 'Package output already exists. Choose a new output directory.'
}
Push-Location $repo_root
try {
    $source_commit = (& git rev-parse --verify HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or $source_commit -notmatch '^[a-f0-9]{40}$') { throw 'Unable to resolve source commit.' }
    & git diff --quiet HEAD -- @product_paths
    if ($LASTEXITCODE -ne 0) { throw 'Product files have uncommitted changes; commit and review them before packaging.' }
    $untracked = @(& git ls-files --others --exclude-standard -- @product_paths)
    if ($LASTEXITCODE -ne 0 -or $untracked.Count -gt 0) { throw 'Product directories contain untracked files; package only a reviewed commit.' }
    $commit_time = [DateTimeOffset]::Parse((& git show -s --format=%cI $source_commit).Trim())
    & git archive --format=zip --prefix=Win11Debloat-koKR/ "--output=$archive_path" $source_commit -- @product_paths
    if ($LASTEXITCODE -ne 0) { throw 'git archive failed.' }
}
finally { Pop-Location }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$build_info = [ordered]@{
    distribution = 'WEBIS Win11Debloat-koKR'
    repository = 'https://github.com/webiscorp/Win11Debloat-koKR'
    upstream = 'https://github.com/Raphire/Win11Debloat'
    source_commit = $source_commit
    source_commit_time = $commit_time.ToUniversalTime().ToString('o')
    package_status = 'validation_candidate_not_stable_release'
    license = 'MIT; original Raphire copyright is retained in LICENSE'
    windows_uat = 'Not asserted by packaging. See docs/localization/STATUS.md.'
}
$archive = [System.IO.Compression.ZipFile]::Open($archive_path, [System.IO.Compression.ZipArchiveMode]::Update)
try {
    $entry = $archive.CreateEntry('Win11Debloat-koKR/BUILD_INFO.json')
    $entry.LastWriteTime = $commit_time
    $writer = [System.IO.StreamWriter]::new($entry.Open(), [System.Text.UTF8Encoding]::new($false))
    try { $writer.Write(($build_info | ConvertTo-Json -Depth 5) + "`n") }
    finally { $writer.Dispose() }
}
finally { $archive.Dispose() }

$archive = [System.IO.Compression.ZipFile]::OpenRead($archive_path)
try {
    foreach ($name in @('LICENSE', 'Win11Debloat.ps1', 'Run.bat', 'BUILD_INFO.json', 'Config/Languages/ko-KR/Chrome.json')) {
        if (-not $archive.GetEntry("Win11Debloat-koKR/$name")) { throw "Package is missing $name." }
    }
    foreach ($entry in $archive.Entries) {
        if (-not $entry.FullName.StartsWith('Win11Debloat-koKR/', [StringComparison]::Ordinal) -or $entry.FullName -match '(^|/)\.\.(/|$)') {
            throw "Unexpected archive path: $($entry.FullName)"
        }
    }
    $license_entry = $archive.GetEntry('Win11Debloat-koKR/LICENSE')
    $license_stream = $license_entry.Open()
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { $license_hash = ([BitConverter]::ToString($sha.ComputeHash($license_stream))).Replace('-', '') }
    finally { $license_stream.Dispose(); $sha.Dispose() }
    if ($license_hash -ne (Get-FileHash -LiteralPath (Join-Path $repo_root 'LICENSE') -Algorithm SHA256).Hash) {
        throw 'The packaged LICENSE differs from the source LICENSE.'
    }
    $entry_count = $archive.Entries.Count
}
finally { $archive.Dispose() }
$package_hash = (Get-FileHash -LiteralPath $archive_path -Algorithm SHA256).Hash.ToLowerInvariant()
[System.IO.File]::WriteAllText($checksums_path, "$package_hash  Win11Debloat.zip`n", [System.Text.Encoding]::ASCII)
[PSCustomObject]@{ source_commit = $source_commit; archive = $archive_path; sha256 = $package_hash; entries = $entry_count; status = 'candidate_package_integrity_pass' }
