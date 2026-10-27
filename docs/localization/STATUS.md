# WEBIS Win11Debloat-koKR 검증 및 인계 현황

- **세션:** `[GW]-WIN11DEBLOAT-[1]`
- **작성 기준일:** 2026-10-27
- **현재 단계:** 한국어 현지화 변경의 PR 검토 및 검증 후보 배포 준비
- **최종 작업 Commit SHA:** `PENDING` — 총괄 담당이 마지막 검증 대상 커밋으로 갱신
- **변경본 GitHub Actions:** 실행 결과 확정 대기(`PENDING`); 아래 표의 판정은 `NOT TESTED`
- **한국어 Windows 10/11 실사용 검증:** `NOT TESTED`
- **공개 안정판 Release:** `BLOCKED` — Windows 실사용·복구 검증 증거 미확보

이 문서는 이번 작업의 검수 결과, 실제 실행한 검사, 미검증 항목과 다음 담당자의 확인 지점을 함께 관리합니다. 소스 검사·Linux의 순수 함수 테스트·호스팅 Windows의 화면 검사는 각각 검증 범위가 다릅니다. 아직 확인되지 않은 Windows 동작을 통과 결과에 포함하지 않습니다.

## 1. 저장소와 비교 기준

### 최초 원격 조회에서 확인한 상태

| 항목 | 확인 결과 |
|---|---|
| 작업 저장소 | [webiscorp/Win11Debloat-koKR](https://github.com/webiscorp/Win11Debloat-koKR) |
| Upstream | [Raphire/Win11Debloat](https://github.com/Raphire/Win11Debloat) |
| Fork 관계 | `fork: true`; `parent.full_name` 및 `source.full_name` 모두 `Raphire/Win11Debloat` |
| 실제 기본 브랜치 | 양쪽 모두 `master` |
| 최초 Fork HEAD | `535a1d871a9dd2cba562c5782a8fbc0d16ad16da` |
| Upstream 비교 기준 HEAD | [`535a1d871a9dd2cba562c5782a8fbc0d16ad16da`](https://github.com/Raphire/Win11Debloat/commit/535a1d871a9dd2cba562c5782a8fbc0d16ad16da) |
| 최초 커밋 차이 | 두 HEAD가 같음. 이번 현지화 변경은 아래 작업 브랜치에서 분리 |
| 초기 원본 CI | [run 40247086487](https://github.com/Raphire/Win11Debloat/actions/runs/40247086487) 성공 |
| 초기 Fork CI | [run 40467611012](https://github.com/webiscorp/Win11Debloat-koKR/actions/runs/40467611012) 성공 |
| 최초 Release 상태 | 원본 최신 Release `2026.08.24`; Fork Release 없음 |
| 한국어판 Issues | 활성화됨. [한국어판 지원 및 제보](https://github.com/webiscorp/Win11Debloat-koKR/issues) |

초기 CI 두 건의 판정 범위는 작업 시작 시 기준 코드입니다. **이번 한국어 변경본의 CI 결과는 별도로 확정해야 합니다.** 다음 Upstream 동기화나 `master` 반영 직전에는 원격 HEAD를 다시 조회합니다.

### 작업 브랜치와 결과물 식별

| 항목 | 현재 기록 |
|---|---|
| 작업 브랜치 | [`webis/korean-localization-20261027`](https://github.com/webiscorp/Win11Debloat-koKR/tree/webis/korean-localization-20261027) |
| 원격 쓰기 확인 | 한국어판 작업 브랜치 생성 및 최초 현지화 커밋 게시 확인 |
| 최초 현지화 커밋 | [`9da61d70c802258be2b9ca50030e9ad08bcfdda5`](https://github.com/webiscorp/Win11Debloat-koKR/commit/9da61d70c802258be2b9ca50030e9ad08bcfdda5) — 전체 변경의 최종 SHA가 아님 |
| 최종 검증 대상 SHA | `PENDING` — 총괄 담당 갱신 |
| PR URL / 병합 결과 | `PENDING` — 총괄 담당 갱신 |
| 변경본 전체 Tests run URL / head SHA | `PENDING` |
| 변경본 Korean localization run URL / head SHA | `PENDING` |
| 후보 ZIP artifact URL / SHA-256 | `PENDING` — 실제 생성·다운로드 검증 후 기입 |
| 한국어판 Release URL | 없음. 공개 안정판 미게시 |

## 2. 완료 기준별 판정

`PASS`는 명시한 범위의 확인·통과, `FAIL`은 실행 결과와 기대값의 불일치, `BLOCKED`는 필요한 환경·증거 등으로 다음 단계 진행 불가, `NOT TESTED`는 미실행입니다. `PENDING`은 실행·기록 갱신 대기 표시이며 통과 판정이 아닙니다.

| 검사 | 상태 | 범위와 근거 |
|---|---|---|
| Fork 관계·기본 브랜치·기준 HEAD | **PASS** | 최초 GitHub 원격 조회. 위 비교 SHA로 고정 |
| 한국어판 원격 쓰기 | **PASS** | 작업 브랜치와 최초 현지화 커밋 게시 확인 |
| 기존 한국어 카탈로그 전수검수 | **PASS** | 1,169개 전체 대조, 135개 개선·1,034개 유지. 키별 CSV 판단·이유 기록 |
| 신규 사용자 문자열과 구조 검증 | **PASS** | 카탈로그 331개 추가; 최종 1,500개 키·서식·검수 기록 검사 통과 |
| 사용자 노출 하드코딩 영어 감사 | **PASS** | 85개 PowerShell 파일·10개 XAML의 후보를 검토하고 예외를 분류. 정적 감사 범위 |
| 한국어 로딩·선택·저장·전환·fallback | **PASS** | 리소스/Pester 및 안전한 bootstrap 검증. 실제 Windows GUI 조작은 아래 별도 판정 |
| CLI 한국어 및 제거 대상 범위 | **PASS** | 실제 대상 결정·매개변수·제거 분배 함수와 mock backend를 결합한 회귀 테스트 |
| Linux에서 Windows 전용 테스트 실행 | **FAIL** | 미지원 Windows 명령·레지스트리·경로로 실패. 동일 기준 코드에서도 같은 실패 목록; 통과로 재분류하지 않음 |
| 변경본 Windows 전체 기능 회귀 CI | **NOT TESTED** | 실제 run 및 head SHA 확인 대기 |
| Windows PowerShell 5.1 리소스·파서 실행 | **NOT TESTED** | 변경본 Windows CI 대기. BOM과 소스 검사는 완료 |
| 호스팅 Windows WPF 표시 검사 | **NOT TESTED** | 비파괴 검사 스크립트·workflow 준비, 실제 실행 및 PNG 검수 대기 |
| 한국어 Windows 10/11 실사용 | **NOT TESTED** | 일반/관리자 권한, 실제 앱 제거·적용·복구·재부팅 미실행 |
| 한국어 사용자·유지보수 문서 | **PASS** | README·사용 가이드·유지보수 지침 및 본 현황 문서 작성 |
| 다운로드 출처·체크섬·설정 보존 | **PASS** | Fork 전용 경로 및 mock 다운로드/재시도 검증. 실제 안정판 다운로드는 Release 미게시로 불가 |
| 원본 LICENSE·앱 ID·레지스트리 정의 보존 | **PASS** | 기준 커밋과 LICENSE·Regfiles·Config/Features.json 차이 없음; 162개 앱 레코드의 AppId 목록 일치 |
| 공개 안정판 발행 | **BLOCKED** | 변경본 CI와 Windows 실사용·복구 검증 완료 전 발행 보류 |

## 3. 번역 검수 수와 수정 범위

### 카탈로그 집계

| 카탈로그 | 기존 검수 문자열 | 기존 문자열 개선 | 기존 문자열 유지 | 신규 문자열 | 현재 문자열 |
|---|---:|---:|---:|---:|---:|
| Apps | 324 | 30 | 294 | 0 | 324 |
| Categories | 12 | 0 | 12 | 0 | 12 |
| Chrome | 341 | 53 | 288 | 331 | 672 |
| Features | 492 | 52 | 440 | 0 | 492 |
| **합계** | **1,169** | **135** | **1,034** | **331** | **1,500** |

집계 단위는 JSON의 문자열 leaf입니다. 135는 오역·용어·명확성·일관성·가독성을 개선한 **문자열 수**이며 서로 다른 기능 결함 135개를 뜻하지 않습니다. 신규 331개와 기존 135개 수정은 별도 집계합니다. 독립 실행기 `Scripts/Get.ps1`의 **한영 문구 정의 18개**는 카탈로그 1,500개에 포함하지 않습니다.

영어와 값이 같은 문자열 **116개**는 제품명·기술 용어로 개별 분류했습니다. [unchanged_english.json](unchanged_english.json)에 현재 영문 값과 유지 이유를 고정하여, 설명·경고의 번역 누락이 허용 목록에 섞이지 않도록 검사합니다.

검수 기록은 [Apps·Categories](review_apps_categories.csv), [Chrome](review_chrome.csv), [Features](review_features.csv), [추가 실행 문자열](review_runtime.csv)에 있습니다. 유지한 항목에도 이유를 기록했고, 신규 문구는 구현 담당과 다른 담당자가 영어·한국어·호출 문맥을 교차 검토했습니다. 최종 구조 검증은 1,500개 모두에 검수 기록이 있고, 키 누락·추가 불일치·서식 오류가 없음을 확인했습니다.

### 주요 변경

- **한국어 카탈로그:** 작업 표시줄·시작 메뉴·파일 탐색기·복원 지점·추천·원격 분석 등의 용어를 일치시켰습니다. 앱 제거와 시작 메뉴 고정 해제, 복원 승인과 완료, 앱 선택 데이터 가져오기와 앱 설치를 구분했습니다. 숨김 항목, WSL, BitLocker 등의 설명을 실제 코드와 대조했습니다.
- **실행 문자열:** `Scripts/CLI/`, `GUI/`, `Features/`, `AppRemoval/`, `Helpers/`, `FileIO/`와 main에서 기존 `Get-Translation` 체계를 사용하도록 정리했습니다. 독립 worker runspace에는 호출 측에서 번역한 메시지 또는 기존 언어 객체·로더를 전달합니다.
- **언어 선택:** 명시적 `-Language`, 저장 설정, Windows UI 문화권의 우선순위를 유지합니다. 한국어판이라는 이유로 저장된 영어 선택을 덮어쓰지 않습니다. 한국어 복수형은 `other`를 사용하고, 리소스 실패 시 영어 fallback·이중언어 bootstrap 진단을 제공합니다.
- **기본 앱 묶음:** `Config/Apps.json`의 두 기본 preset에 선택적 `PresetId`를 추가하여 표시 이름을 번역합니다. 기존 `Name`과 `AppIds`는 보존하며, ID가 없는 기존·사용자 정의 preset은 원래 이름을 사용합니다. 기존 JSON 키를 이름 변경하거나 삭제하지 않았습니다.
- **배포·문서:** README를 한국어 진입점으로 정리하고 영문 참고, 실행·복구·유지보수 문서를 `docs/localization/`에 배치했습니다. 한국어판 다운로드·지원 링크와 원본 출처·후원 링크를 구분했습니다. About 화면에 WEBIS 현지화 및 비공식 배포판 정체성을 표시합니다.
- **검증:** 기존 Tests workflow를 유지하고 한국어 카탈로그·PowerShell 리소스·비파괴 WPF·검증 후보 패키지 workflow를 추가했습니다. 자동 안정판 발행은 구성하지 않았습니다.

## 4. 검수에서 발견하여 수정한 주요 문제

| 문제 | 수정 및 현재 상태 | 검증 근거와 한계 |
|---|---|---|
| Mark-of-the-Web 처리 전에 초기 언어 helper를 로드하면 다운로드 파일 차단 처리 순서가 바뀔 수 있음 | **PASS — 소스 순서 교정.** 기존 파일 차단 처리 전에는 JSON만 읽고, helper dot-source 및 전체 언어 초기화는 기존 차단 처리 뒤에 수행 | source 교차 검수 및 bootstrap 언어 우선순위 5건 통과. 실제 Windows ADS·실행 정책 동작은 **NOT TESTED** |
| 압축 해제 실패 뒤 다음 실행의 정리가 `ConfigOld`의 저장 설정을 삭제 | **PASS — 수정 후 회귀 검사 통과.** 별도 staging 경로에 먼저 추출·필수 파일을 확인하고, 기존 설정을 보호하며 오래된 실행기의 `ConfigOld`를 복구 | 초기 실패를 두 담당자가 독립 재현. `Get-ArchiveHash.Tests.ps1`의 연속 추출 실패·중단된 기존 실행기의 설정 복구 검사로 수정 확인 |
| 내부 timeout 문자열을 번역하면 WinGet catch의 sentinel 매칭이 깨짐 | **PASS — 내부 계약 복원.** sentinel은 보존하고 사용자 표시 경계에서 번역 | 실제 timeout/runspace 로직에 무해한 지연 작업을 넣은 한영×GUI/CLI 4건. 오류 1회, 실패 반환, 후속 작업 가능 여부 확인 |
| WhatIf 후 GUI가 실제 변경을 적용했다고 표시 | **PASS — 표시 분기 교정.** 미리 보기 완료 제목·설명·로그를 별도로 사용 | 실제 완료 분기를 AST로 추출한 한영×재시작 선택 4건과 일반 성공 2건. 실제 변경 함수·WPF는 호출하지 않음 |
| CLI가 CurrentUser·지정 사용자에도 고정된 모든 사용자 범위를 안내 | **PASS — 표시 인수 교정.** 기본 메뉴가 실제 대상 이름을 전달하고, 수동 선택 확인은 범위를 단정하지 않는 문구 사용 | 신규 9건: 기본 메뉴 대상 4종, 수동 선택·분배 대상 3종, 취소·Silent. 제거 명령 자체는 변경 없음 |
| 원본 URL을 통해 한국어판으로 안내되거나 무검증 source ZIP으로 전환될 가능성 | **PASS — 배포 경로 분리.** 안정판은 Fork의 ZIP·SHA256SUMS 필수; 누락·불일치 시 중단. 명시적 Dev만 Fork 소스 사용 | 실제 launcher를 호출하되 다운로드·프로세스를 mock한 검사. 실제 한국어판 안정판 asset은 아직 없음 |

문제 발견 단계의 임시 보고서에는 실패·수정 대기 상태가 남아 있을 수 있습니다. 위 표는 후속 소스 수정과 해당 회귀 검증을 반영한 현재 기록입니다. 화면 표시 문구 수정과 다운로드·설정 보존 수정은 앱 제거·레지스트리 적용 로직의 변경과 구분해 검토했습니다.

## 5. 실제 자동 검사 결과

로컬 검증 환경은 **Linux, PowerShell 7.6.9, Pester 5.9.0**입니다. Python 검증기는 Python 3 표준 라이브러리를 사용합니다. 제품의 지원 실행 환경인 Windows PowerShell 5.1에서 Windows 앱·설정을 실제 적용했다는 뜻은 아닙니다.

**아래 실행 묶음은 서로 중복됩니다. 통과·실패 수를 더하여 전체 테스트 수로 보고하지 않습니다.** 각 결과는 실행 당시 변경 스냅샷에 대한 근거이며, 최종 커밋의 Windows CI를 별도로 확인해야 합니다.

| 실행 범위 | 실제 결과 | 근거 |
|---|---:|---|
| 총괄 담당의 후보 로컬 묶음 6개 파일 | **135 PASS / 0 FAIL** | Get-ArchiveHash, KoreanLocalization, Show-CliMenuOptions, Import-JsonFile, Import-LanguageFile, TestSuiteSafety. `/tmp/webis_candidate_local_tests.log` |
| 한국어 구조 검증기 | **PASS**, 현재 **1,500/1,500** 검수 기록, 의도적 영문 **116개**, 오류 **0개** | `Scripts/Test-KoreanLocalization.py`; `/tmp/webis_catalog_validation.json` |
| 구조 검증기의 부정 입력·회귀 fixture | **7 PASS / 0 FAIL** | 중복·대소문자 충돌, 잘못된 escape/UTF-8/JSON 상수, 빈 값, 서식 토큰 검사 |
| KoreanLocalization 리소스 전용 | **8 PASS / 0 FAIL** | 독립 재실행도 동일. `/tmp/webis-independent-korean-pester.log` |
| 런타임/기능 담당 10개 테스트 파일 | **271개 중 216 PASS / 55 FAIL** | 기준 코드 267개 중 212 PASS / 55 FAIL. 실패 테스트 경로 집합 동일, 새 한국어 검사 4개 통과. `/tmp/webis-runtime-final-test.log`, `webis-runtime-baseline-test.log` |
| Helpers·FileIO·인수 처리 교차 검수 8개 파일 | **193개 중 181 PASS / 12 FAIL** | 동일 환경의 기준 코드도 193/181/12, 실패 경로 차이 0개. `/tmp/webis-review-root-tests.json`, `webis-review-root-baseline-tests.json` |
| timeout 통합 회귀 + 안전성 | **12 PASS / 0 FAIL** | 독립 검수 담당 실행: Invoke-NonBlocking 기존 6개·신규 4개, TestSuiteSafety 2개 |
| WhatIf 완료 + preset + 다운로드 + 안전성 | **35 PASS / 0 FAIL** | 독립 검수 담당 실행: ApplyCompletion-Localization 신규 6개, Import-AppPresetsFromJson, Get-ArchiveHash, TestSuiteSafety |
| CLI 대상 범위 최종 독립 재실행 | **16 PASS / 0 FAIL** | 기존 7개+신규 9개. `/tmp/webis-cli-scope-regression.log` |
| 안전성 검사 최종 독립 재실행 | **2 PASS / 0 FAIL** | `/tmp/webis-cli-scope-safety.log` |
| main bootstrap의 언어 우선순위·리소스 누락 | **5 PASS / 0 FAIL** | 임시 프로필에서 실제 Core 차단 이전 경로 실행, 각 기대 종료 코드 1. `/tmp/webis-bootstrap-review.json` |
| PowerShell 소스 파싱·변경 공백 검사 | **PASS — 수행한 검사 범위** | Scripts/Features·AppRemoval·Tests 파싱 오류 0; 후속 Tests는 TestSuiteSafety의 AST 파싱 포함. 변경 파일 `git diff --check` 통과 |

Linux 실패는 실제 실패로 기록했습니다. 원본에서도 동일하게 실패한 원인은 Windows 전용 Appx·예약 작업·CIM·로컬 사용자 명령, ACL·레지스트리, Windows 드라이브/경로, 네이티브 `powershell.exe` 의존성입니다. 실패를 없애기 위해 기존 assertion을 삭제하거나 해당 검사를 임의로 건너뛰지 않았습니다. 실패 목록이 같다는 사실은 해당 환경에서 새 실패가 없다는 근거이며 Windows 전체 기능 동등성의 최종 증거는 아닙니다.

### 변경본 CI의 갱신 항목

| Workflow/환경 | 현재 판정 | 확정할 기록 |
|---|---|---|
| 기존 `Tests` — Windows PowerShell 5.1 전체 Pester 및 PSScriptAnalyzer | **NOT TESTED / PENDING** | run URL, head SHA, 결과·테스트 수, 분석 오류 |
| `Korean localization` — Ubuntu 카탈로그 | **NOT TESTED / PENDING** | run URL, JSON artifact, 실제 집계 |
| `Korean localization` — Windows PowerShell 5.1/7 리소스 matrix | **NOT TESTED / PENDING** | 두 환경 각각 XML 결과·버전·테스트 수 |
| `Korean localization` — 호스팅 Windows WPF | **NOT TESTED / PENDING** | host OS/이미지, `ui-report.json`, PNG 실제 열람 결과 |
| `Korean localization` — 검증 후보 패키지 | **NOT TESTED / PENDING** | ZIP·SHA256SUMS·BUILD_INFO·artifact URL |

검증 후보 패키지 job은 같은 한국어 workflow의 선행 job에 의존합니다. **기존 전체 `Tests` workflow 결과도 별도로 확인**해야 합니다. workflow 파일이 존재하거나 기준 커밋의 CI가 성공했다는 사실만으로 변경본 행을 PASS로 갱신하지 않습니다.

## 6. GUI·CLI 및 Windows 실사용 범위

### 확인된 범위

- 명시적 ko-KR이 저장된 en-US보다 우선하고, 명시적 en-US가 저장된 ko-KR보다 우선합니다. 명시 언어가 없으면 저장된 선택을 사용하며 Auto는 한국어 UI 문화권을 따릅니다.
- 리소스 테스트는 ko-KR 전체 로딩, 영어 fallback, BOM 유무, 서식 문자열, 저장 설정 유지·한영 전환, XAML 마커 치환을 확인했습니다. bootstrap에서 리소스를 읽지 못하면 자체 이중언어 진단을 제공합니다.
- CLI 테스트는 한국어 메뉴·개수·취소·Silent와 실제 대상 매개변수 보존을 확인했습니다. 한국어 앱 제거 및 복원 지점 메시지를 별도 runspace에 전달하는 검사도 통과했습니다.
- 비파괴 WPF 스크립트는 구현·독립 소스 검수를 마쳤습니다. 제품 main/Get 및 적용 작업을 호출하지 않고 카탈로그 데이터로 화면을 구성합니다. 실제 WPF 실행 결과는 아직 없습니다.

### 반드시 남겨 둘 미검증 항목

| 항목 | 상태 | 필요한 환경·증거 |
|---|---|---|
| 한국어 Windows 11 GUI/CLI 실제 실행 | **NOT TESTED** | 에디션·빌드·PowerShell·표시 언어와 실행 SHA, 화면·로그 |
| 한국어 Windows 10 GUI/CLI 실제 실행 | **NOT TESTED** | 지원 빌드에서 동일 기록 및 Windows 10 차이 확인 |
| 일반 권한·UAC 승격/거절·관리자 실행, Run.bat/Windows Terminal | **NOT TESTED** | 네이티브 Windows 실행 기록 |
| 한글 IME 조합 입력·검색·키보드 접근성 | **NOT TESTED** | 실제 입력 장치·화면 조작 기록 |
| 라이트/다크·최소 창·긴 문장·실제 고해상도/100·150·200% 배율 | **NOT TESTED** | 실제 Windows 표시 배율별 화면과 문제 수정 확인 |
| 앱 제거 전 확인·대상 범위·적용·실패·제거 후 확인 | **NOT TESTED** | 격리 VM의 테스트 앱, 사전 스냅샷과 결과 |
| 설정 적용·레지스트리 백업·복원·시작 메뉴 복구·복원 지점 | **NOT TESTED** | 격리 VM에서 변경 전후와 복구 결과 |
| Explorer 재시작·재부팅 후 상태 | **NOT TESTED** | 격리 VM의 재시작·재부팅 기록 |

WPF 스크립트의 96/144/192 DPI는 **PNG 렌더링 밀도**입니다. 실제 Windows 표시 배율 검증과 구분합니다. 자동 잘림 검사는 버튼 계열 내부의 줄바꿈·말줄임 없는 한글 TextBlock 폭 중심이며 모든 UI 컨트롤을 보장하지 않습니다. 호스팅 Windows Server의 결과를 한국어 Windows 10/11 실사용 결과로 기록하지 않습니다. 운영 PC에서 파괴적 변경 테스트를 실행하지 않았습니다.

## 7. 하드코딩 영어 잔여의 분류

출력·질문·throw·컨트롤 속성 후보 및 AST의 영문 다단어 후보 111개를 검토했습니다. 후보 수에는 경로·기술 식별자·개발 도구·bootstrap 문구가 포함되므로 번역 결함 수가 아닙니다. 검토 후보에서 추가 일반 사용자용 영어 메뉴·확인 문구는 발견하지 못했습니다.

| 잔여 유형 | 유지 근거 |
|---|---|
| `Operation timed out after ...` 2곳 | catch가 판별하는 내부 sentinel. 사용자 경계의 오류 문장은 번역하고 진단 원문을 보존 |
| `Get-SelectedRegistryFeaturesForBackupValidation requires Errors ...` | 잘못된 함수 인수를 전달한 프로그래밍 계약 예외 |
| 영문 literal Write-Verbose 6곳, `Stack trace:` 2곳 | 개발 진단. 일반 오류·진행 안내는 별도 한국어 문구 사용 |
| 언어 커버리지 비교·Run-Tests·Test-KoreanUi·Build-KoreanPackage 메시지 | 개발·검증·패키지 도구의 출력 |
| WinGet·Appx·Win32·레지스트리 예외 원문 | 외부 OS/도구의 진단 보존. 한국어 문맥을 제공하되 오류 식별자를 번역하지 않음 |
| `System Tweaks`, `Deployment Settings` | 가져오기·내보내기의 내부 분류 식별자. 표시 이름은 번역 함수로 해결 |
| Windows 서비스·작업·레지스트리·앱 ID·정규식·글꼴 이름 | 명령·조회·기존 데이터 호환성에 필요한 기술 값 |
| 복원창 `SelectType`, `Registry`, `StartMenu` 탭 헤더 | 탭 자체가 Collapsed·높이 0인 내부 전환 식별자. 실제 탐색 UI는 번역 리소스 사용 |
| MessageBox의 `Message content goes here` | ShowDialog 전에 호출자가 전달한 메시지로 교체되는 설계용 값 |
| Raphire·WEBIS·제품명·원본 URL·언어의 원어 이름 | 출처·식별·언어 선택을 위한 고유명 |
| 초기 JSON/언어 로딩·제한된 언어 모드 진단 | 카탈로그 실패를 안내할 수 있도록 한국어/영어를 자체 포함 |

다음 업데이트에서도 허용 분류를 새 영어 문구의 무조건적인 예외로 사용하지 않습니다. 일반 사용자에게 실제 노출되는 새 설명·경고는 기존 카탈로그로 옮기고, 사용자 입력·제품명·OS 원문은 구분해 검토합니다.

## 8. 배포 파일·라이선스·출처

[Build-KoreanPackage.ps1](../../Scripts/Build-KoreanPackage.ps1)는 커밋한 제품 파일만 묶으며, 미커밋·미추적 제품 파일이 있으면 중단합니다. ZIP에는 `Win11Debloat-koKR/` 아래 원본 LICENSE·실행 파일·리소스·문서와 `BUILD_INFO.json`이 들어가며, 같은 ZIP의 `SHA256SUMS`를 생성합니다. 현재 패키지 상태 표시는 `validation_candidate_not_stable_release`입니다.

- 실제 후보 ZIP/artifact URL: **PENDING**
- ZIP의 실제 SHA-256: **PENDING**
- BUILD_INFO의 실제 `source_commit`: **PENDING**
- 공개 안정판 Release: **미게시 / BLOCKED**
- [한국어판 Releases](https://github.com/webiscorp/Win11Debloat-koKR/releases), [원본 Releases](https://github.com/Raphire/Win11Debloat/releases)

`Scripts/Get.ps1`의 안정판 경로는 한국어판의 `Win11Debloat.zip`과 `SHA256SUMS`를 요구합니다. Release가 없거나 체크섬이 맞지 않으면 실행을 중단합니다. 명시적 `-Dev`는 한국어판 `master` 소스이며 안정판 검증 대상으로 표시하지 않습니다. 현재 문서는 검증되지 않은 원격 즉시 실행 명령을 사용자 설치 방법으로 제시하지 않습니다.

원본 [LICENSE](../../LICENSE)의 MIT 및 Raphire 저작권 고지를 유지했습니다. 한국어판은 WEBIS의 현지화·설명·필요한 오류 수정이며 원본 제작자의 공식 배포판으로 표시하지 않습니다. 후원·원본 출처 링크도 보존합니다. 기준 커밋 대비 LICENSE·Regfiles·Config/Features.json은 변경하지 않았고, 162개 앱 레코드의 패키지 ID 목록이 동일함을 재확인했습니다.

## 9. 남은 작업과 다음 실행 순서

현재 공개 안정판을 막는 항목은 **변경본 Windows CI 및 실제 Windows 10/11 적용·복구 검증의 증거 부재**입니다. Linux의 기존 실패를 통과로 처리하거나 테스트를 약화해 이 조건을 충족한 것으로 만들지 않습니다.

1. 원격 `master` 및 작업 브랜치 HEAD를 다시 확인하고, 전체 변경을 검토 가능한 커밋·PR로 확정합니다. 이 문서의 최종 SHA와 PR URL을 갱신합니다.
2. **같은 최종 SHA**의 기존 Tests와 Korean localization을 실제 실행하여 모든 job 결과·버전·테스트 수·run URL을 기록합니다. 실패가 있으면 환경 문제와 변경 회귀를 구분해 수정한 뒤 다시 실행합니다.
3. WPF artifact의 JSON과 PNG를 직접 열어 한국어 표시·언어 전환·검색·자동 측정 경고를 확인합니다. 자동 검사 범위 밖의 실제 IME·표시 배율·접근성은 별도 검증 항목으로 유지합니다.
4. 한국어 Windows 10/11의 격리 VM과 사전 스냅샷/복구 수단을 준비하여 §6의 실제 적용·복구·재시작 절차를 실행합니다. OS 빌드·권한·SHA·실행 전후 증거를 기록합니다.
5. 검증 후보 ZIP을 실제 내려받아 SHA256SUMS, BUILD_INFO의 SHA, 압축 경로, LICENSE·한국어 리소스를 확인하고 artifact URL·해시를 기입합니다. CI artifact의 보존 기간은 현재 30일이므로 장기 인계에 필요한 증거를 별도로 보존합니다.
6. PR 검토와 해당 품질 기준을 통과한 변경만 `master`에 반영합니다. 안정판 조건을 충족한 뒤 최종 커밋·Upstream SHA·검증 환경·제한·출처·체크섬을 포함한 Release를 준비합니다. 미검증 상태에서는 검증 후보로 유지합니다.

### 다음 Upstream 업데이트의 주의점

- 동기화 기준은 이 문서에 기록한 Upstream SHA입니다. 최신 원격 확인 후 기능·언어 키·Windows 빌드 조건을 비교하고, 자동 감지와 병합·배포를 별도 단계로 유지합니다.
- 신규 문자열은 카탈로그뿐 아니라 main/Get/Run.bat·CLI·worker runspace·오류 처리·완료 분기도 점검합니다. 새 키의 en-US fallback과 한국어의 서식 인수·입력 문자 `y/n`을 보존합니다.
- timeout sentinel과 같은 내부 매칭 값은 표시 문구와 구분합니다. 언어 로더를 Mark-of-the-Web 처리 앞으로 이동하거나 runspace에 없는 번역 함수를 호출하지 않습니다.
- 앱 preset의 선택적 `PresetId`, 기존 사용자 이름·테마·언어 설정, LastUsedSettings·백업 파일 형식을 보존합니다. 다운로드 ZIP의 루트 구조가 바뀌면 staging·복구 회귀 검사를 함께 갱신합니다.
- 원본 Release/후원 주소와 한국어판 다운로드/지원 주소를 구분합니다. 원본 변경을 무검증으로 안정판 자동 배포하지 않습니다.
- [유지보수 지침](MAINTENANCE.ko-KR.md)의 검수·검증 절차를 따르고, 해당 실행의 SHA와 실제 결과로 이 문서를 갱신합니다.

## 10. 인계 자료와 증거 위치

| 목적 | 저장소 내 자료 |
|---|---|
| 사용자 진입·설치 안내 | [README](../../README.md) |
| 실행·기능·복구·FAQ | [한국어 사용 가이드](USER_GUIDE.ko-KR.md) |
| 영문 참고 문서 | [README.en.md](README.en.md) |
| 용어·Upstream 동기화·테스트·배포 절차 | [MAINTENANCE.ko-KR.md](MAINTENANCE.ko-KR.md) |
| 기존/신규 번역의 개별 판단 | [Apps·Categories](review_apps_categories.csv), [Chrome](review_chrome.csv), [Features](review_features.csv), [runtime](review_runtime.csv) |
| 동일 영문 허용 근거 | [unchanged_english.json](unchanged_english.json) |
| 재실행 가능한 검사 | [Tests](../../Tests/), [카탈로그 검증기](../../Scripts/Test-KoreanLocalization.py), [비파괴 WPF 검사](../../Scripts/Test-KoreanUi.ps1) |
| CI와 패키지 | [기존 Tests](../../.github/workflows/tests.yml), [한국어 workflow](../../.github/workflows/korean-localization.yml), [패키지 빌더](../../Scripts/Build-KoreanPackage.ps1) |

이번 세션의 원시 로그는 §5의 `/tmp` 경로 및 `/tmp/webis_final_source_audit.md`, `/tmp/webis_independent_root_review.md`, `/tmp/webis_new_strings_review.md`에 있습니다. 임시 파일은 장기 보존을 보장하지 않으므로 핵심 수치·판정·재현 가능한 테스트는 본 문서와 저장소에 옮겼습니다. 최종 인계 시에는 **확정 SHA의 실제 CI run URL과 artifact**를 위 빈 항목에 추가해야 합니다. 중간 스냅샷의 1,497개 집계나 수정 전 실패 보고보다 이 문서의 최종 1,500개 집계 및 후속 검증 결과를 우선합니다.
