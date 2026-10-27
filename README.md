# Win11Debloat 한국어판 · WEBIS

**Windows의 불필요한 앱과 추천 콘텐츠를 정리하고, 원하는 시스템 설정을 한국어로 선택할 수 있는 PowerShell 도구입니다.**

이 저장소는 [Raphire/Win11Debloat](https://github.com/Raphire/Win11Debloat)의 **비공식 한국어 현지화 Fork**입니다. 원본 제작자는 **Raphire**, 한국어 번역 검수·사용 문서·한국어판 유지보수는 **WEBIS**가 담당합니다. 원본에 이미 포함된 한국어 언어팩과 기능을 기반으로 개선하며, 원본 공식 배포판을 뜻하지 않습니다.

[한국어 사용 가이드](docs/localization/USER_GUIDE.ko-KR.md) · [검증 상태와 남은 과제](docs/localization/STATUS.md) · [번역·Upstream 유지보수](docs/localization/MAINTENANCE.ko-KR.md) · [한국어판 Releases](https://github.com/webiscorp/Win11Debloat-koKR/releases)

> [!IMPORTANT]
> **현재 한국어판은 검증 중이며 공개 안정판으로 확정되지 않았습니다.** 자동 테스트 결과와 한국어 Windows 10/11 실사용 검증은 별도입니다. 실행 환경·통과한 검사·미검증 항목은 [검증 기록](docs/localization/STATUS.md)을 확인하세요. 앱 제거와 시스템 변경은 복구 가능한 별도 테스트 PC 또는 VM에서 먼저 확인하세요.

## 무엇을 할 수 있나요?

| 기능 | 사용 예 |
|---|---|
| 앱 제거 | 설치된 앱을 검색하고 제거할 앱과 적용 대상을 선택 |
| 개인 정보 및 추천 콘텐츠 | 원격 분석(텔레메트리), 광고·추천·검색 연동 관련 설정 조정 |
| 시작 메뉴·작업 표시줄 | 정렬, 검색 표시, 추천 영역, 고정된 앱 등 조정 |
| 파일 탐색기 | 파일 확장명·숨김 항목 표시, 기본 시작 위치와 탐색 창 조정 |
| AI·게임·시스템 | 지원되는 Windows 빌드의 AI 기능, Game Bar, 전원 관련 옵션 조정 |
| 설정 재사용과 복구 | 설정 파일 가져오기·내보내기, 레지스트리 백업과 시작 메뉴 백업 복원 |

모든 옵션을 적용할 필요는 없습니다. **사용 중인 기능과 제거 대상 앱을 확인하고 필요한 항목만 선택하세요.** Windows 버전에 따라 표시되거나 적용 가능한 옵션이 다릅니다. 한국어판은 앱 ID, 레지스트리 경로, 명령행 매개변수와 기존 설정·백업 형식을 유지합니다.

## 실행 환경

- 원본의 대상 운영체제: **Windows 10 / Windows 11**. 한국어판의 실제 확인 범위는 검증 기록에 별도로 표시합니다.
- 제품 실행: **Windows PowerShell 5.1**(`powershell.exe`) 및 관리자 권한.
- GUI: Windows의 WPF 구성 요소를 사용합니다.
- **PowerShell 7(`pwsh`)에서는 제품 실행을 지원하지 않습니다.** 현재 프로그램은 해당 환경에서 중단하도록 설계되어 있습니다. PowerShell 7에서 일부 테스트를 실행할 수 있다는 사실은 제품 지원을 뜻하지 않습니다.
- 별도 설치 프로그램은 없습니다. ZIP을 풀어 실행합니다. Appx·WinGet 등 실제 기능의 가용성은 Windows 환경에 따라 달라집니다.

## 다운로드와 첫 실행

### 1. 한국어판 파일 받기

[**WEBIS 한국어판 Releases**](https://github.com/webiscorp/Win11Debloat-koKR/releases)에서 검증 상태와 설명을 먼저 확인하세요. 안정판이 게시되지 않았다면 안정판 다운로드 파일은 아직 없습니다.

개발 검토가 필요할 때만 [한국어판 `master` 소스 ZIP](https://github.com/webiscorp/Win11Debloat-koKR/archive/refs/heads/master.zip)을 사용하세요. 소스 ZIP은 개발판이며 안정판·무결성 검증 완료 배포물을 뜻하지 않습니다. 작업 브랜치의 변경은 `master`에 병합된 뒤 포함됩니다.

ZIP을 압축 해제한 폴더에는 `Run.bat`, `Win11Debloat.ps1`, `Config`, `Scripts`, `Schemas` 등이 함께 있어야 합니다. ZIP 내부에서 바로 실행하거나 `Win11Debloat.ps1` 하나만 따로 옮기지 마세요.

### 2. GUI 열기

1. 압축을 푼 폴더에서 **`Run.bat`**를 실행합니다.
2. Windows 사용자 계정 컨트롤(UAC)에서 관리자 권한 실행을 확인합니다.
3. 기존 언어 설정이 없고 Windows 표시 언어가 한국어이면 한국어가 자동 선택됩니다.
4. 다른 언어가 표시되면 상단 **설정 → 언어**에서 한국어를 선택한 뒤 **저장**합니다. 기존에 저장한 언어는 자동으로 덮어쓰지 않습니다.
5. 앱 제거·시스템 조정·배포 설정을 확인하고 **선택한 변경 사항 검토**를 거친 뒤 적용합니다.

### 3. PowerShell에서 한국어로 열기

관리자 권한의 **Windows PowerShell**에서 압축 해제한 폴더로 이동한 후 실행합니다.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Win11Debloat.ps1 -Language ko-KR
```

`-ExecutionPolicy Bypass`는 이 프로세스 실행에 한정됩니다. 조직 정책으로 실행이 제한되어 있으면 담당 관리자에게 확인하세요.

대화형 CLI는 다음과 같이 엽니다.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Win11Debloat.ps1 -Language ko-KR -CLI
```

**다운로드 경로를 구분하세요.** `debloat.raphi.re`와 `Raphire/Win11Debloat/releases`는 **원본 배포 경로**입니다. WEBIS 한국어판 설치 명령으로 안내하지 않습니다. 한국어판 원격 다운로드·즉시 실행 명령은 별도 검증 전까지 제공하지 않습니다.

## 적용 전에 알아둘 점

- 앱 제거의 기본 대상은 **모든 사용자**일 수 있습니다. **배포 설정 → 앱 제거 대상**에서 범위를 확인하세요. Microsoft Store, 터미널, Xbox 구성 요소, 제조사 도구를 제거하면 앱 설치·현재 실행 세션·게임·장치 기능에 영향을 줄 수 있습니다.
- 레지스트리 백업은 선택한 변경에 관련된 레지스트리 상태를 보존합니다. **삭제한 앱, 사용자 파일, Windows 전체를 백업하는 기능이 아닙니다.**
- 시스템 복원 지점은 별도 기능이며, Windows 상태에 따라 생성에 실패하거나 최근 복원 지점을 재사용할 수 있습니다. 성공 메시지를 확인하세요.
- 파일 탐색기 재시작 시 작업 표시줄과 바탕 화면이 잠시 사라지거나 깜박일 수 있습니다. 일부 기능은 PC를 다시 시작해야 완전히 적용됩니다.
- 개인정보 관련 옵션은 개별 설정을 변경합니다. 모든 데이터 수집 중단이나 성능 향상을 보장하지 않습니다.

## 백업과 되돌리기

GUI의 **백업 복원**에서 레지스트리 또는 시작 메뉴 백업을 선택하고, 적용 대상과 복원 가능한 항목을 확인한 뒤 진행합니다. 설정 파일 내보내기는 선택 목록 저장이며 시스템 백업과 다릅니다.

일반 실행의 데이터 위치는 다음과 같습니다.

| 종류 | 위치 |
|---|---|
| 언어·테마 | `%LOCALAPPDATA%\Win11Debloat\Preferences.json` |
| 마지막 선택 | `%LOCALAPPDATA%\Win11Debloat\LastUsedSettings.json` |
| 레지스트리 백업 | `%LOCALAPPDATA%\Win11Debloat\Backups` |
| 실행 로그 | `%LOCALAPPDATA%\Win11Debloat\Logs` |
| 시작 메뉴 고정 앱 백업 | 각 사용자의 `StartMenuExperienceHost` 패키지 `LocalState` 폴더에 생성되는 `Win11Debloat-StartBackup-*.bak` |

일부 배포 환경처럼 `LOCALAPPDATA`가 없으면 메인 스크립트는 실행 폴더를 데이터 기준 위치로 사용합니다. 관리자 권한으로 실행한 계정과 적용 대상 계정이 다르면 데이터 위치도 주의해야 합니다.

앱 재설치와 비레지스트리 변경 복구에는 별도 절차가 필요할 수 있습니다. [복구 범위와 단계별 안내](docs/localization/USER_GUIDE.ko-KR.md#recovery)를 먼저 읽어주세요.

<a id="support"></a>

## 업데이트·문제 보고

- 원본 변경 감지, 한국어 번역 반영, 테스트, Release 발행을 구분합니다. 원본을 자동 병합했다는 이유만으로 한국어판을 자동 배포하지 않습니다.
- 새 버전을 적용하기 전 변경 내역과 Windows 빌드 지원 범위를 확인하고, 기존 설정·로그·백업을 보관하세요.
- 번역·한국어판 다운로드·실행 문제는 [한국어판 Issues](https://github.com/webiscorp/Win11Debloat-koKR/issues)에 등록하세요. 원본 기능 문제는 원본에서도 재현되는지 구분하여 보고합니다.
- 보고 시 Windows 버전·빌드, PowerShell 버전, 한국어판 커밋 또는 배포 버전, 재현 단계, 오류 문구를 포함하세요. 로그의 계정명·개인 경로·기타 민감정보는 공개 전에 가리세요.

자세한 사용법과 FAQ는 [한국어 사용 가이드](docs/localization/USER_GUIDE.ko-KR.md), 개발 절차는 [유지보수 문서](docs/localization/MAINTENANCE.ko-KR.md)를 참고하세요.

## 원본·라이선스·후원

- 원본 프로젝트·제작자: [Raphire/Win11Debloat](https://github.com/Raphire/Win11Debloat), Raphire.
- 한국어 현지화·유지보수: [WEBIS](https://github.com/webiscorp).
- [MIT LICENSE](LICENSE)와 원저작권 고지를 그대로 유지합니다.
- [원본 제작자 후원(Ko-fi)](https://ko-fi.com/M4M5C6UPC): 후원은 원본 제작자에게 전달됩니다.
- [보존된 원본 영문 README](docs/localization/README.en.md)는 원문 자료입니다. 그 안의 설치·지원 링크는 원본 프로젝트용입니다. 원문 위치 기준 이미지·링크는 [Upstream README](https://github.com/Raphire/Win11Debloat/blob/master/README.md)에서 볼 수 있습니다.
