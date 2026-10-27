# 한국어 번역과 Upstream 유지보수

이 문서는 **WEBIS Win11Debloat-koKR 유지보수자와 기여자**를 위한 작업 기준입니다. 제품 사용 방법은 [사용 가이드](USER_GUIDE.ko-KR.md), 현재 커밋·검수 수치·실행한 테스트·미검증 항목은 [검증 기록](STATUS.md)을 기준으로 확인합니다.

한국어판은 [Raphire/Win11Debloat](https://github.com/Raphire/Win11Debloat)의 비공식 Fork입니다. 기능 동등성과 기존 설정·백업 호환성을 우선하며, 한국어 번역을 이유로 적용 엔진을 재작성하지 않습니다. 원본 [LICENSE](../../LICENSE), 저작권·후원·출처 고지, GitHub Fork 관계를 유지합니다. 보호되는 작업 지침과 기존 테스트·기록을 임의로 변경하거나 삭제하지 않습니다.

## 1. 작업 위치와 기록

| 위치 | 용도 |
|---|---|
| `Config/Languages/en-US/` | 영어 기준 카탈로그. 새 사용자 메시지는 영어 기준도 함께 등록 |
| `Config/Languages/ko-KR/` | 한국어 Apps·Categories·Chrome·Features 카탈로그 |
| `review_apps_categories.csv` | 앱 이름·설명과 범주 전체의 검수 판단 |
| `review_chrome.csv`, `review_features.csv` | 기존 화면 문자열과 기능·선택값의 검수 판단 |
| `review_runtime.csv` | CLI·초기 실행·오류·복구 등 추가한 실행 문자열의 검수 판단 |
| `unchanged_english.json` | 영어와 같은 값을 의도적으로 보존한 항목의 정확한 값과 이유 |
| [STATUS.md](STATUS.md) | 비교 SHA, 변경 수, 실행 환경, 테스트·CI 증거, 미해결 사항과 인계 |
| [README.en.md](README.en.md) | 초기 작업 기준 원본 README의 보존본. 현재 사용자 안내는 한국어 README 사용 |

위 상대 파일은 이 문서와 같은 `docs/localization/` 폴더에 있습니다. 별도의 중복 보고서나 오래된 TODO를 저장소 최상위에 쌓지 않습니다. 검수 기준과 최종 결과는 이 문서 및 `STATUS.md`에 연결하고, 일시적인 실행 결과는 CI artifact 또는 저장소 밖의 작업 폴더에서 관리합니다.

### 검수 CSV 읽기와 갱신

모든 문자열 말단 값마다 `key,status,reason` 한 행을 유지합니다. 예를 들어 `Apps.Microsoft.WindowsCalculator.Description`은 앱 설명이고, `Chrome.CliRemovePrompt`는 화면·실행 메시지입니다. `Features.json`의 키는 실제 최상위 객체에 따라 `Features.<ID>.<필드>` 또는 `UiGroups.<ID>.<필드>`로 기록합니다. 앱 ID 자체에 포함된 점은 이름의 일부이므로 임의로 분리하거나 고치지 않습니다.

| status | 의미 |
|---|---|
| `kept` | 영어 의미·기능·한국어 품질을 확인하고 기존 값을 유지 |
| `changed` | 기존 번역을 수정. 수정 이유를 `reason`에 기록 |
| `added` | 새 카탈로그 항목을 영어와 대조하여 추가 |

`kept`는 미검수라는 뜻이 아닙니다. 같은 키를 여러 CSV에 중복 등록하지 않으며, 신규·삭제·수정된 키의 기록도 함께 갱신합니다. 다음 업데이트에서는 `STATUS.md`에 비교 기준 SHA를 기록하고 그 기준으로 변경 이유를 정리합니다. 과거 검수 내용은 Git 이력으로 추적할 수 있어야 합니다. 행 존재 여부를 검사하는 자동화가 사람이 문장을 읽었다는 증거를 대신하지는 않습니다.

## 2. 번역 정책과 용어

기존의 정확하고 자연스러운 번역을 보존합니다. 기능 이름은 짧고 구별 가능하게, 설명과 경고는 완결된 존댓말로 작성합니다. 삭제 대상·영향·복구 한계·재시작 필요 여부를 원문과 실제 기능에 맞게 전달합니다. 원문에 없는 안전성, 성능 개선, 완전 복구를 보장하지 않습니다.

| 영어/문맥 | 한국어 기준 |
|---|---|
| Taskbar / Start menu | 작업 표시줄 / 시작 메뉴 |
| File Explorer | 파일 탐색기 |
| Restore point / Registry | 복원 지점 / 레지스트리 |
| Telemetry | 원격 분석(텔레메트리); 문맥이 분명한 반복 표기는 원격 분석 |
| Recommended / Notifications | 추천 / 알림 |
| Settings / Configuration 화면 | 설정 |
| Import / Export configuration | 설정 파일 가져오기 / 설정 파일 내보내기 |
| Device companion apps / Battery life | 장치 보조 앱 / 배터리 사용 시간 |
| WhatIf | 작업 미리 보기(WhatIf); 실제 적용 완료와 구별 |

Microsoft 한국어 Windows 표기를 우선하되, 특정 앱의 공식 이름과 Windows 프로세스 이름은 문맥을 확인합니다. 예를 들어 Explorer 재시작은 파일 탐색기 창뿐 아니라 작업 표시줄 등 셸에 영향을 줄 수 있으므로 창만 닫는 동작처럼 설명하지 않습니다.

**그대로 보존할 항목:** 제품명·앱 식별자, PowerShell 명령어와 매개변수, 함수·클래스, JSON 키, 서비스 이름, 레지스트리 경로와 값, 파일명·경로, 환경 변수, 정규식, 오류 코드, 메시지 자리표시자와 서식입니다. `{0}`과 `{1}`의 표시 순서는 문법에 따라 바꿀 수 있지만 인수 의미·개수·서식은 보존해야 합니다. 사용자에게 보이는 문자열은 기존 `Get-Translation` 및 XAML 리소스 체계를 사용하고, 개발용 진단 식별자와 외부 명령의 원문 출력은 구분합니다.

### 의도적인 영어 값

`unchanged_english.json`에는 다음 세 요소를 사람이 검토해 기록합니다.

- `english_value`: 영어와 한국어에서 정확히 같은 현재 문자열.
- `classification`: 제품명은 `product_name`, 기술 용어는 `technical_term`.
- `reason`: 번역 누락이 아니라 그대로 두어야 하는 이유.

제품명이 아닌 설명·경고를 영어로 남긴 뒤 허용 목록에 넣어 검증을 통과시키지 않습니다. 값이 바뀌거나 번역되어 더 이상 같지 않으면 목록을 갱신하거나 삭제합니다. CI는 이 목록을 자동으로 추가하거나 갱신하지 않습니다. 현재 항목 수는 고정 목표가 아니며 검증 보고서에서 확인합니다.

UTF-8을 사용하고 기존 파일의 BOM·줄바꿈을 불필요하게 일괄 변경하지 않습니다. PowerShell 5.1에서 읽는 한글 포함 스크립트는 실제 디코딩을 확인하고 기존 인코딩 방식을 보존합니다. JSON의 BOM 유무는 모두 리소스 테스트 대상입니다.

## 3. Upstream 업데이트 순서

**원본 변경 감지, 코드 병합, 한국어판 배포는 별도 단계입니다.** 변경 알림을 자동화해도 무검증 자동 병합·안정판 발행으로 연결하지 않습니다.

1. GitHub에서 한국어판이 원본 `Raphire/Win11Debloat`의 Fork인지, 양쪽 실제 기본 브랜치와 최신 HEAD·Release·CI 상태를 확인합니다. API를 사용할 때는 `fork`, `parent.full_name`, `source.full_name`, `default_branch` 및 접근 권한을 확인합니다. 초기 기록만으로 현재 상태를 추정하지 않습니다.
2. `origin`은 `webiscorp/Win11Debloat-koKR`, `upstream`은 `Raphire/Win11Debloat`인지 점검합니다. `upstream`이 없다면 읽기용 원본 remote를 등록합니다. 원본에 직접 push하지 않습니다.
3. 최신 원격 참조를 가져와 직전 검수한 Upstream SHA와 신규 SHA 사이의 파일·기능·문자열 차이를 확인합니다. 원본과 Fork 양쪽의 새 변경을 확인한 뒤 작업 브랜치를 만듭니다.
4. 변경분을 검토해 작업 브랜치에 반영하고 충돌을 기능별로 해소합니다. 카탈로그 전체를 덮어쓰거나 어느 한쪽을 일괄 선택해 해결하지 않습니다. 새 옵션의 실제 동작과 설명, 설정·백업 형식, 실행 인수 및 Windows 빌드 제한을 함께 대조합니다.
5. en-US/ko-KR 신규·변경 키를 번역하고 CSV·의도적 영어 분류를 갱신합니다. 런처·CLI·GUI·오류 처리의 카탈로그 밖 새 사용자 문자열도 검색합니다. 다른 언어의 미추가 키에는 기존 영어 fallback 체계를 유지합니다.
6. 아래 자동 검사와 영향을 받는 실사용 검증을 실행한 뒤 Fork의 `master`를 대상으로 PR을 만듭니다. 비교 SHA, 변경 이유, 기능 변경 여부, 테스트 범위·미실행 항목을 PR에 기록합니다.

다음 명령은 원격과 이력을 확인하는 예입니다. **실제 기본 브랜치가 달라졌으면 `master`를 확인한 값으로 바꿉니다.**

```powershell
git remote -v
git ls-remote --symref origin HEAD
git ls-remote --symref upstream HEAD
git fetch origin
git fetch upstream
git rev-parse origin/master upstream/master
git log --oneline --left-right origin/master...upstream/master
```

초기 Upstream 기준은 `535a1d871a9dd2cba562c5782a8fbc0d16ad16da`입니다. 다음 예의 `$previous_upstream_sha`는 이후 작업마다 `STATUS.md`에 기록한 **직전 검수 SHA**로 갱신합니다. 원격 최신 SHA는 실제 fetch 결과로 확정합니다.

```powershell
$previous_upstream_sha = '535a1d871a9dd2cba562c5782a8fbc0d16ad16da'
$next_upstream_sha = (git rev-parse upstream/master).Trim()
git diff --name-status $previous_upstream_sha $next_upstream_sha
git diff $previous_upstream_sha $next_upstream_sha -- Config/Languages/en-US Config/Features.json Config/Apps.json
```

작업 브랜치 예시는 `webis/upstream-YYYYMMDD` 또는 `webis/korean-localization-YYYYMMDD`입니다. `master` 반영 직전 원격 HEAD를 다시 확인하고 다른 기여자의 변경을 보존합니다. 강제 push·Fork 관계 변경·검증 없는 강제 병합을 하지 않습니다. PR을 통한 검토를 우선하며 **실제로 통과한 회귀 테스트와 변경 범위에 필요한 품질 검증**을 근거로 병합합니다. `master` 병합만으로 안정판 배포 조건이 충족되는 것은 아닙니다.

## 4. 자동 검사 실행과 해석

모든 명령은 저장소 루트에서 실행합니다. Python 검증과 Pester는 제품 진입 스크립트를 실행하는 절차가 아닙니다. 일반 사용자 권한으로 실행 가능한 검사는 일반 권한을 사용합니다.

### 카탈로그·검수 기록

```powershell
python Scripts/Test-KoreanLocalization.py --self_test --report artifacts/korean-catalogs.json
```

Python 3 표준 라이브러리를 사용합니다. 환경에 따라 `python3` 명령을 사용합니다. [검증기](../../Scripts/Test-KoreanLocalization.py)는 다음을 검사합니다.

- 4개 카탈로그의 엄격한 UTF-8/JSON, BOM 위치, Escape, 중복·대소문자 충돌 키, 빈 값·잘못된 값 형식.
- 영어 대비 한국어 키 누락·추가, 자리표시자 개수·인수·정렬/서식, 잘못된 중괄호.
- 모든 키의 유효한 CSV 판단·이유 및 중복·오래된 검수 키.
- 영어와 동일한 값의 개별 분류, 변경된 영어 값 또는 더 이상 필요하지 않은 허용 목록 항목.

구조 검사 PASS가 한국어 자연스러움이나 기능 안전성을 인증하지는 않습니다. 신규·변경 문장의 의미 검수는 별도로 수행합니다.

### PowerShell 테스트

기존 전체 회귀 테스트는 **Windows PowerShell 5.1**에서 실행합니다. 최초 `-Bootstrap`은 현재 사용자 범위에 필요한 Pester를 설치할 수 있으므로 테스트용 개발 환경에서 사용합니다.

```powershell
powershell.exe -NoProfile -File .\Scripts\Run-Tests.ps1 -Bootstrap
```

이미 Pester 5가 있으면 `-Bootstrap`을 생략합니다. 특정 한국어 리소스 변경을 확인할 때는 다음과 같이 실행할 수 있습니다.

```powershell
Invoke-Pester -Path .\Tests\KoreanLocalization.Tests.ps1 -Output Detailed
```

[한국어 테스트](../../Tests/KoreanLocalization.Tests.ps1)는 ko-KR 로딩, 영어 fallback, 서식 문자열, BOM 유무, 한국어 자동 선택, 명시 언어의 우선순위, 저장 설정 유지·전환과 XAML 치환을 확인합니다. 기존 [전체 테스트](../../Tests/)와 [안전성 검사](../../Tests/TestSuiteSafety.Tests.ps1)를 유지합니다. 실제 앱 제거·레지스트리 변경·재부팅을 CI 테스트에 추가하지 말고 적절한 mock과 임시 경로를 사용합니다.

**제품 실행 지원은 Windows PowerShell 5.1입니다.** PowerShell 7의 한국어 리소스 테스트는 파일 로딩·순수 함수·설정 호환성 확인이며 제품 GUI/CLI나 Appx·시스템 복원 기능을 지원한다는 뜻이 아닙니다. Linux에서 통과한 순수 함수 테스트도 Windows 전체 회귀 테스트를 대신하지 않습니다.

### 비파괴 WPF 표시 검사

Windows의 대화형 데스크톱과 Windows PowerShell 5.1에서 다음 명령을 실행합니다.

```powershell
powershell.exe -NoProfile -STA -File .\Scripts\Test-KoreanUi.ps1 -output_path .\artifacts\korean-ui
```

[표시 검사](../../Scripts/Test-KoreanUi.ps1)는 한정된 리소스·UI 함수와 고정 앱 데이터를 사용합니다. `Win11Debloat.ps1`, `Get.ps1` 또는 실제 변경 엔진을 실행하지 않습니다. 밝게/어둡게, 주요 창과 탭, 프로그램에서 입력한 한국어 검색·앱 ID 검색, 언어 갱신, 일부 버튼의 한글 텍스트 폭을 확인하고 PNG와 `ui-report.json`을 만듭니다.

**96/144/192 DPI PNG 생성은 Windows 표시 배율 100/150/200% 실사용 검사가 아닙니다.** 한글 IME 조합 입력, 모든 컨트롤의 줄바꿈·키보드 접근성, 실제 모니터 배율, Windows 10/11 앱 적용·복구는 별도 검사합니다. `windows-latest` 호스팅 러너의 OS·이미지·실제 DPI를 보고서에 기록하고, Windows Server 러너 결과를 한국어 Windows 10/11 결과로 표기하지 않습니다.

### CI 결과 확인

기존 [tests.yml](../../.github/workflows/tests.yml)은 Windows PowerShell 5.1 전체 Pester와 오류 수준 PSScriptAnalyzer를 실행합니다. 추가한 [korean-localization.yml](../../.github/workflows/korean-localization.yml)은 카탈로그 검사, PowerShell 5.1/7 리소스 테스트, WPF 표시 검사 및 검증 후보 패키지를 준비합니다.

PR·`master` push·수동 실행의 **실제 run URL과 head SHA**, 실패·취소·건너뜀 여부, 테스트 수와 artifact를 확인합니다. 워크플로 파일 존재만으로 PASS 처리하지 않습니다. 후보 패키지 job은 같은 한국어 workflow의 선행 검사에 의존하지만 기존 `Tests` workflow의 성공까지 자동으로 보장하지 않으므로 두 workflow를 모두 확인해야 합니다. 현재 artifact 보존 기간은 30일이므로 인계 시 만료될 링크만 남기지 말고 필요한 증거와 실행 식별자를 프로젝트 기록에 보존합니다.

## 5. Windows 실사용 검증과 안정판 조건

앱·설정·레지스트리 변경은 운영 PC에서 시험하지 않습니다. **한국어 Windows 10과 Windows 11의 격리된 VM 또는 전용 테스트 환경에 스냅샷/복구 수단을 확보**하고, 적용·실패·복구 결과를 확인합니다. 테스트한 OS 에디션·빌드·표시 언어, PowerShell 버전, 권한, 소스 SHA, 수행한 절차와 로그/화면 증거를 `STATUS.md`에 연결합니다.

| 검증 영역 | 안정판 판단에 필요한 증거 |
|---|---|
| 실행과 언어 | 일반 권한의 UAC 승격·거절, 관리자 실행, GUI/CLI, ko-KR 자동 선택, 명시 언어와 저장 설정 우선순위, 영어↔한국어 전환, 손상 리소스 fallback |
| 실제 화면 | 밝게/어둡게, 창 크기 변경·최소 크기, 긴 설명·경고, 버튼/체크박스 잘림, 실제 100/150/200% 배율, 고해상도, 한글 IME 조합·검색, 키보드 조작 |
| 앱 제거 | 적용 전 앱 이름·제거 범위 확인, 현재/전체/지정 사용자 대상, 취소·부분 실패·검증 불가, 제거 후 상태. 테스트에 사용하는 앱과 복구 방법을 사전에 정함 |
| 설정과 미리 보기 | 지원 빌드에서 선택한 설정의 실제 변화, WhatIf와 실제 적용 완료 안내의 구별, 기존 설정 파일 가져오기·내보내기 |
| 백업과 복구 | 레지스트리 자동 백업·복원, 복원 지점 성공/실패 처리, 시작 메뉴 백업·복원, 복구 대상 확인, 기존 백업 형식 호환성 |
| 종료와 재시작 | 취소한 뒤 이미 적용된 변경의 상태, Explorer 재시작, 재부팅 필요 안내와 실제 재부팅 후 동작 |

앱 제거·Copilot 제거 등을 레지스트리 Undo만으로 완전히 복구한다고 판단하지 않습니다. 시스템 복원 지점이나 설정 내보내기도 전체 앱·파일·OS 이미지 백업과 구분합니다. Windows 업데이트 뒤 관련 기능·레지스트리 동작이 달라졌다면 해당 빌드에서 재검증합니다.

검사별 상태는 `PASS`(해당 범위 실행·통과), `FAIL`(실행·기대 결과 불일치), `BLOCKED`(환경·권한 등으로 진행 불가), `NOT TESTED`(미실행)로 기록합니다. 미실행을 PASS로 합산하지 않습니다. Windows 실사용 및 중요한 복구·안전성 항목에 증거가 없으면 **공개 안정판 발행을 보류**합니다. 자동 검사 통과 범위의 변경을 PR로 정리하거나 검증 후보 artifact를 준비하는 일과 안정판 확정을 구별합니다.

## 6. 패키지와 배포 경로

[패키지 빌더](../../Scripts/Build-KoreanPackage.ps1)는 검토·커밋한 제품 파일을 현재 HEAD에서만 묶고, 제품 경로의 수정·미추적 파일이 있으면 중단합니다. 기존 출력 ZIP/체크섬을 덮어쓰지 않으므로 새 출력 폴더를 지정합니다.

```powershell
powershell.exe -NoProfile -File .\Scripts\Build-KoreanPackage.ps1 -output_path .\artifacts\candidate-YYYYMMDD
```

| 생성물 | 계약 |
|---|---|
| `Win11Debloat.zip` | 단일 `Win11Debloat-koKR/` 폴더 아래 실행 파일·리소스·문서·원본 LICENSE 포함 |
| `Win11Debloat-koKR/BUILD_INFO.json` | 소스 전체 Commit SHA·시각·Fork/원본 주소·라이선스·검증 후보 상태 기록 |
| `SHA256SUMS` | 같은 ZIP의 SHA-256과 정확한 파일명 `Win11Debloat.zip` 기록 |

빌더는 ZIP 내 필수 파일·경로·LICENSE 일치와 해시를 검사합니다. 현재 `BUILD_INFO.json`의 상태는 `validation_candidate_not_stable_release`이며 패키징이 Windows 실사용을 인증하지 않는다고 명시합니다. 이 생성물은 CI의 검증 후보 artifact입니다. **현재 CI는 Release를 자동 발행하지 않습니다.** UAT 증거를 확보한 뒤 안정판의 메타데이터·배포 절차를 별도로 검토해야 하며, 검증 이후 ZIP 내용을 수동으로 변경해 이전 체크섬을 재사용해서는 안 됩니다.

[한국어판 `Scripts/Get.ps1`](../../Scripts/Get.ps1)의 안정판 경로는 **`webiscorp/Win11Debloat-koKR`의 Release**입니다. `Win11Debloat.zip`과 `SHA256SUMS`가 모두 있어야 하며 해시가 일치하지 않거나 파일이 없으면 중단합니다. 원본 배포판이나 무해시 소스 ZIP으로 자동 전환하지 않습니다. 명시적인 `-Dev`만 Fork `master` 소스 아카이브를 사용하며, 이는 게시된 안정판 체크섬으로 검증된 파일이 아닙니다.

`debloat.raphi.re`와 `Raphire/Win11Debloat/releases`는 원본 배포 경로입니다. README·Release·지원 안내·테스트 예제가 이를 한국어판 설치 주소로 잘못 소개하지 않는지 점검합니다. 사용자에게 검증되지 않은 원격 즉시 실행 명령을 안내하지 않습니다.

안정판을 게시할 때는 최종 커밋과 Upstream 비교 SHA, 지원·검증 환경, 변경 범위, 알려진 제한, MIT·Raphire 원저작자·WEBIS 현지화 표시를 Release에 포함합니다. 동일한 Release에 ZIP과 체크섬을 함께 제공하고 실제 다운로드 파일을 재검증합니다. 체크섬은 배포 파일의 동일성을 확인하며 코드 안전성·복구 가능성을 보장하지 않습니다.

## 7. PR과 결과 인계

PR은 번역, 사용자 안내, 필요한 기능 수정, 테스트를 검토 가능한 단위로 구분합니다. 기능 수정은 번역과 별도로 이유와 회귀 검증을 설명합니다. 관련 없는 리팩터링이나 기존 지침 변경을 함께 넣지 않습니다.

`STATUS.md`에 최종 Fork SHA·Upstream SHA, 실제 수정 파일과 검수/수정 수, 테스트 환경·결과·CI run 링크, 패키지 SHA-256·artifact/Release 위치, Windows 미검증 항목과 후속 조치를 기록합니다. 실행하지 못한 검사와 존재하지 않는 Release는 그대로 `NOT TESTED`/미게시로 표시합니다. [한국어판 Issues](https://github.com/webiscorp/Win11Debloat-koKR/issues)에는 재현 조건과 로그에서 개인 정보를 제거한 증거를 남기고, 원본에 전달할 문제는 한국어판 변경과 원본에서도 재현되는 동작을 구분해 정리합니다.
