param (
    [switch]$Verbose,
    [switch]$WhatIf,
    [switch]$Dev,
    [switch]$CLI,
    [switch]$Silent,
    [switch]$Sysprep,
    [string]$LogPath,
    [string]$Language,
    [string]$User,
    [Alias('NoRestartExplorer')]
    [switch]$SkipExplorerRestart,
    [switch]$CreateRestorePoint,
    [switch]$SkipRegistryBackup,
    [switch]$RunDefaults,
    [switch]$RunDefaultsLite,
    [switch]$RunSavedSettings,
    [string]$Config,
    [string]$Apps,
    [string]$AppRemovalTarget,
    [switch]$RemoveApps,
    [switch]$RemoveGamingApps,
    [switch]$RemoveHPApps,
    [switch]$ForceRemoveEdge,
    [switch]$DisableDVR,
    [switch]$DisableGameBarIntegration,
    [switch]$EnableWindowsSandbox,
    [switch]$EnableWindowsSubsystemForLinux,
    [switch]$DisableTelemetry,
    [switch]$DisableFastStartup,
    [switch]$DisableBitlockerAutoEncryption,
    [switch]$DisableModernStandbyNetworking,
    [switch]$DisableNotifications,
    [switch]$DisableStorageSense,
    [switch]$DisableUpdateASAP,
    [switch]$PreventUpdateAutoReboot,
    [switch]$DisableDeliveryOptimization,
    [switch]$DisableDeviceAutoAppDownload,
    [switch]$DisableBing,
    [switch]$DisableStoreSearchSuggestions,
    [switch]$DisableDesktopSpotlight,
    [switch]$HideDesktopSpotlightIcon,
    [switch]$EnableDesktopSpotlight,
    [switch]$DisableLockscreenTips,
    [switch]$DisableSuggestions,
    [switch]$DisableLocationServices,
    [switch]$DisableFindMyDevice,
    [switch]$DisableEdgeAds,
    [switch]$DisableBraveBloat,
    [switch]$DisableSettings365Ads,
    [switch]$DisableSettingsHome,
    [switch]$ShowHiddenFolders,
    [switch]$ShowKnownFileExt,
    [switch]$HideDupliDrive,
    [switch]$EnableDarkMode,
    [switch]$DisableTransparency,
    [switch]$DisableAnimations,
    [switch]$TaskbarAlignLeft,
    [switch]$CombineTaskbarAlways, [switch]$CombineTaskbarWhenFull, [switch]$CombineTaskbarNever,
    [switch]$CombineMMTaskbarAlways, [switch]$CombineMMTaskbarWhenFull, [switch]$CombineMMTaskbarNever,
    [switch]$MMTaskbarModeAll, [switch]$MMTaskbarModeMainActive, [switch]$MMTaskbarModeActive,
    [switch]$HideSearchTb, [switch]$ShowSearchIconTb, [switch]$ShowSearchLabelTb, [switch]$ShowSearchBoxTb,
    [switch]$HideTaskview,
    [switch]$DisableStartRecommended,
    [switch]$DisableStartAllApps, [switch]$StartAllAppsCategory, [switch]$StartAllAppsGrid, [switch]$StartAllAppsList,
    [switch]$DisableStartPhoneLink,
    [switch]$DisableCopilot,
    [switch]$DisableRecall,
    [switch]$DisableClickToDo,
    [switch]$DisableAISvcAutoStart,
    [switch]$DisablePaintAI,
    [switch]$DisableNotepadAI,
    [switch]$DisableEdgeAI,
	[switch]$DisableChromeAI,
    [switch]$DisableWidgets,
    [switch]$HideChat,
    [switch]$EnableEndTask,
    [switch]$EnableLastActiveClick,
    [switch]$ClearStart,
    [string]$ReplaceStart,
    [switch]$ClearStartAllUsers,
    [string]$ReplaceStartAllUsers,
    [switch]$RevertContextMenu,
    [switch]$DisableMouseAcceleration,
    [switch]$DisableStickyKeys,
    [switch]$DisableWindowSnapping,
    [switch]$DisableSnapAssist,
    [switch]$DisableSnapLayouts,
    [switch]$HideTabsInAltTab, [switch]$Show3TabsInAltTab, [switch]$Show5TabsInAltTab, [switch]$Show20TabsInAltTab,
    [switch]$HideHome,
    [switch]$HideGallery,
    [switch]$ExplorerToHome,
    [switch]$ExplorerToThisPC,
    [switch]$ExplorerToDownloads,
    [switch]$ExplorerToOneDrive,
    [switch]$AddFoldersToThisPC,
    [switch]$HideOnedrive,
    [switch]$Hide3dObjects,
    [switch]$HideMusic,
    [switch]$HideIncludeInLibrary,
    [switch]$HideGiveAccessTo,
    [switch]$HideShare,
    [switch]$ShowDriveLettersFirst,
    [switch]$ShowDriveLettersLast,
    [switch]$ShowNetworkDriveLettersFirst,
    [switch]$HideDriveLetters
)

# Do not run bootstrap initialization under a restricted PowerShell language mode.
if ($ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage') {
    Write-Error 'PowerShell execution is restricted by security policies. / 보안 정책으로 PowerShell 실행이 제한되어 있습니다.'
    Exit 1
}

# Standalone bootstrap text: resources are not downloaded yet.
# Explicit language overrides saved preferences; otherwise follow Windows UI culture.
$launcher_language = $Language
if (-not $launcher_language -and $env:LOCALAPPDATA) {
    $launcher_preferences_path = Join-Path (Join-Path $env:LOCALAPPDATA 'Win11Debloat') 'Preferences.json'
    if (Test-Path -LiteralPath $launcher_preferences_path) {
        try { $launcher_language = (Get-Content -LiteralPath $launcher_preferences_path -Raw -Encoding UTF8 | ConvertFrom-Json).Language } catch { }
    }
}
if (-not $launcher_language -or $launcher_language -eq 'Auto') { $launcher_language = [System.Globalization.CultureInfo]::CurrentUICulture.Name }
$launcher_korean = $launcher_language -match '^ko(?:-|$)'
$launcher_text = @{
    Restricted = @('Win11Debloat is unable to run on your system, PowerShell execution is restricted by security policies', '보안 정책으로 PowerShell 실행이 제한되어 Win11Debloat를 실행할 수 없습니다.')
    ExitKey = @('Press any key to exit...', '종료하려면 아무 키나 누르세요...')
    Title = @(' Win11Debloat Script', ' WEBIS Win11Debloat 한국어판 (비공식 현지화)')
    Development = @('> Downloading development version of Win11Debloat...', '> 한국어판 개발 소스를 내려받는 중... 안정판이 아니며 게시된 배포 체크섬 검증 대상이 아닙니다.')
    Download = @('> Downloading Win11Debloat...', '> Win11Debloat 한국어판을 내려받는 중...')
    FetchFailed = @('Unable to fetch required files from GitHub. Please check your internet connection and try again.', 'GitHub에서 한국어판 파일을 가져오지 못했습니다. 안정판 Release 게시 여부와 인터넷 연결을 확인하세요. 원본 배포판으로 전환하지 않습니다.')
    ExitEnter = @('Press enter to exit...', '종료하려면 Enter 키를 누르세요...')
    HashMismatch = @('The downloaded Win11Debloat archive does not match the SHA-256 checksum published with the release.', '내려받은 ZIP의 SHA-256이 Release의 체크섬과 다릅니다. 파일을 실행하지 않습니다.')
    CleanOld = @('> Cleaning up old script files...', '> 이전 스크립트 파일을 정리하는 중...')
    BackupConfig = @('> Backing up existing config files...', '> 기존 설정 파일을 보존하는 중...')
    Unpack = @('> Unpacking...', '> 압축을 푸는 중...')
    RestoreConfig = @('> Restoring existing config files...', '> 기존 설정 파일을 복원하는 중...')
    Launch = @('> Launching Win11Debloat...', '> Win11Debloat 한국어판을 시작하는 중...')
    Cleanup = @('> Cleaning up...', '> 임시 스크립트 파일을 정리하는 중...')
    LaunchFailed = @('Failed to start Win11Debloat: {0}', 'Win11Debloat를 시작하지 못했습니다: {0}')
    ChecksumMissing = @('The Korean release must include Win11Debloat.zip and SHA256SUMS. No unverified archive will be executed.', '한국어판 Release에 Win11Debloat.zip과 SHA256SUMS가 모두 있어야 합니다. 검증되지 않은 압축 파일은 실행하지 않습니다.')
    ChecksumEntryMissing = @('{0} does not list {1}.', '{0}에 {1}의 체크섬이 없습니다.')
    ArchiveInvalid = @('The archive does not contain the expected Win11Debloat files.', '압축 파일에 필요한 Win11Debloat 파일이 없습니다.')
}
function get_launcher_text {
    param([string]$key, [object[]]$format_args)
    $message = $launcher_text[$key][[int][bool]$launcher_korean]
    if ($format_args -and $format_args.Count) { return $message -f $format_args }
    return $message
}

Clear-Host
Write-Output "-------------------------------------------------------------------------------------------"
Write-Output (get_launcher_text -key 'Title')
Write-Output "-------------------------------------------------------------------------------------------"

$tempRootPath = $env:TEMP
$tempWorkPath = Join-Path $tempRootPath 'Win11Debloat-koKR'
# Isolate downloads per invocation so another launcher cannot replace a verified ZIP.
$download_directory = Join-Path $tempRootPath ('Win11Debloat-koKR-download-' + [guid]::NewGuid().ToString('N'))
[void][System.IO.Directory]::CreateDirectory($download_directory)
$tempArchivePath = Join-Path $download_directory 'win11debloat.zip'

# Read the expected SHA-256 of a file from the text of a SHA256SUMS file (lines of "<64 hex digits>  <file name>", as
# written by sha256sum). Returns $null when the file is not listed.
function Get-ExpectedFileHash([string]$SumsText, [string]$FileName) {
    foreach ($line in ($SumsText -split "`r?`n")) {
        if ($line -match '^([0-9a-fA-F]{64})\s+\*?(.+?)\s*$' -and $Matches[2] -ceq $FileName) {
            return $Matches[1].ToLowerInvariant()
        }
    }
    return $null
}

# Check a file against an expected SHA-256 value (hex digits, any case).
function Test-FileHashMatch([string]$Path, [string]$ExpectedHash) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -ieq $ExpectedHash
}

# Stable Korean downloads require both release assets. Only explicit -Dev uses a source archive.
$releaseArchiveName = 'Win11Debloat.zip'
$releaseChecksumsName = 'SHA256SUMS'
$expectedArchiveHash = $null

# Download Win11Debloat from GitHub as a zip archive.
try {
    if ($Dev) {
        Write-Output (get_launcher_text -key 'Development')
        $sourceUri = "https://github.com/webiscorp/Win11Debloat-koKR/archive/refs/heads/master.zip"
    } else {
        Write-Output (get_launcher_text -key 'Download')
        $release = Invoke-RestMethod https://api.github.com/repos/webiscorp/Win11Debloat-koKR/releases/latest

        $archiveAsset = @($release.assets | Where-Object { $_.name -ceq $releaseArchiveName }) | Select-Object -First 1
        $checksumsAsset = @($release.assets | Where-Object { $_.name -ceq $releaseChecksumsName }) | Select-Object -First 1
        if (-not $archiveAsset -or -not $checksumsAsset) {
            throw (get_launcher_text -key 'ChecksumMissing')
        }
        if ($archiveAsset -and $checksumsAsset) {
            $checksumsPath = Join-Path $download_directory 'SHA256SUMS'
            Invoke-RestMethod $checksumsAsset.browser_download_url -OutFile $checksumsPath
            $expectedArchiveHash = Get-ExpectedFileHash ([System.IO.File]::ReadAllText($checksumsPath)) $releaseArchiveName
            Remove-Item $checksumsPath -Force
            if (-not $expectedArchiveHash) {
                throw (get_launcher_text -key 'ChecksumEntryMissing' -format_args @($releaseChecksumsName, $releaseArchiveName))
            }
            $sourceUri = $archiveAsset.browser_download_url
        }
    }
    Invoke-RestMethod $sourceUri -OutFile $tempArchivePath
}
catch {
    Remove-Item -LiteralPath $download_directory -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host (get_launcher_text -key 'FetchFailed') -ForegroundColor Red
    Write-Error -ErrorRecord $_
    Write-Output ""
    Write-Output (get_launcher_text -key 'ExitEnter')
    Read-Host | Out-Null
    Exit 1
}

# Do not use an archive that differs from the checksum published with the release
if ($expectedArchiveHash -and -not (Test-FileHashMatch $tempArchivePath $expectedArchiveHash)) {
    Remove-Item -LiteralPath $download_directory -Recurse -Force
    Write-Host (get_launcher_text -key 'HashMismatch') -ForegroundColor Red
    Write-Output ""
    Write-Output (get_launcher_text -key 'ExitEnter')
    Read-Host | Out-Null
    Exit 1
}

# Extract and validate in isolation before touching any previous installation or settings.
Write-Output ""
Write-Output (get_launcher_text -key 'Unpack')
$staging_path = Join-Path $download_directory 'payload'
try {
    Expand-Archive -LiteralPath $tempArchivePath -DestinationPath $staging_path -ErrorAction Stop
    $payload_path = $staging_path
    if (-not (Test-Path -LiteralPath (Join-Path $payload_path 'Win11Debloat.ps1'))) {
        $archive_roots = @(Get-ChildItem -LiteralPath $staging_path -Directory | Where-Object {
            Test-Path -LiteralPath (Join-Path $_.FullName 'Win11Debloat.ps1')
        })
        if ($archive_roots.Count -ne 1) { throw (get_launcher_text -key 'ArchiveInvalid') }
        $payload_path = $archive_roots[0].FullName
    }
    foreach ($required_path in @('Win11Debloat.ps1', 'LICENSE', 'Config/Features.json', 'Config/Apps.json', 'Config/Languages/en-US/Chrome.json', 'Config/Languages/ko-KR/Chrome.json', 'Scripts/FileIO/Import-LanguageFile.ps1')) {
        if (-not (Test-Path -LiteralPath (Join-Path $payload_path $required_path) -PathType Leaf)) {
            throw (get_launcher_text -key 'ArchiveInvalid')
        }
    }
}
catch {
    Remove-Item -LiteralPath $download_directory -Recurse -Force -ErrorAction SilentlyContinue
    throw
}

# Keep interrupted legacy backups as well as current LocalAppData-fallback files.
# Windows PowerShell 5.1 ignores -Exclude with -LiteralPath; filter names explicitly.
if (Test-Path $tempWorkPath) {
    Write-Output ""
    Write-Output (get_launcher_text -key 'CleanOld')
    Get-ChildItem -LiteralPath $tempWorkPath -Force |
        Where-Object { $_.Name -notin @('Config', 'ConfigOld', 'Logs', 'Backups', 'LastUsedSettings.json', 'Preferences.json') } |
        ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop }
}
[void][System.IO.Directory]::CreateDirectory($tempWorkPath)
$configDir = Join-Path $tempWorkPath 'Config'
$backupDir = Join-Path $tempWorkPath 'ConfigOld'
$filesToKeep = @('LastUsedSettings.json', 'Preferences.json')
if (Test-Path -LiteralPath $configDir) {
    Write-Output (get_launcher_text -key 'BackupConfig')
    [void][System.IO.Directory]::CreateDirectory($backupDir)
    foreach ($file_name in $filesToKeep) {
        $source_path = Join-Path $configDir $file_name
        $backup_path = Join-Path $backupDir $file_name
        if (Test-Path -LiteralPath $source_path -PathType Leaf) {
            if (Test-Path -LiteralPath $backup_path) {
                # Preserve both generations when recovering an interrupted older launcher.
                Move-Item -LiteralPath $backup_path -Destination ($backup_path + '.previous-' + [guid]::NewGuid().ToString('N')) -ErrorAction Stop
            }
            Move-Item -LiteralPath $source_path -Destination $backup_path -ErrorAction Stop
        }
    }
    Remove-Item -LiteralPath $configDir -Recurse -Force -ErrorAction Stop
}
Get-ChildItem -LiteralPath $payload_path -Force | Move-Item -Destination $tempWorkPath -Force -ErrorAction Stop
if (Test-Path -LiteralPath $backupDir) {
    Write-Output (get_launcher_text -key 'RestoreConfig')
    foreach ($file_name in $filesToKeep) {
        $backup_path = Join-Path $backupDir $file_name
        if (Test-Path -LiteralPath $backup_path -PathType Leaf) {
            Move-Item -LiteralPath $backup_path -Destination (Join-Path $configDir $file_name) -Force -ErrorAction Stop
        }
    }
    if (@(Get-ChildItem -LiteralPath $backupDir -Force).Count -eq 0) {
        Remove-Item -LiteralPath $backupDir -Force -ErrorAction Stop
    }
}
Remove-Item -LiteralPath $download_directory -Recurse -Force

# Quote a value so it survives CommandLineToArgvW parsing in the child process: double any backslash run that
# precedes a quote or the closing quote, and escape embedded quotes, before wrapping the value in quotes.
function Format-LauncherArg([string]$Value) {
    $escaped = $Value -replace '(\\*)"', '$1$1\"'
    $escaped = $escaped -replace '(\\+)$', '$1$1'
    return '"' + $escaped + '"'
}

# Build the list of arguments to pass on to the script (excludes the -Dev switch, which only affects this launcher).
# Takes the bound parameters as input so it can be tested without running the launcher.
function Get-LauncherArgumentList([System.Collections.IDictionary]$BoundParameters) {
    foreach ($entry in $BoundParameters.GetEnumerator()) {
        if ($entry.Key -eq 'Dev') { continue }

        if ($entry.Value -is [System.Management.Automation.SwitchParameter]) {
            if ($entry.Value.IsPresent) {
                "-$($entry.Key)"
            }
        }
        else {
            "-$($entry.Key) $(Format-LauncherArg ([string]$entry.Value))"
        }
    }
}

$arguments = @(Get-LauncherArgumentList $PSBoundParameters)

Write-Output ""
Write-Output (get_launcher_text -key 'Launch')

# Minimize the PowerShell window when no parameters are provided
if ($arguments.Count -eq 0) {
    $windowStyle = "Minimized"
}
else {
    $windowStyle = "Normal"
}

# Remove PowerShell 7 modules from path to prevent module loading issues in the script
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $NewPSModulePath = $env:PSModulePath -split ';' | Where-Object -FilterScript { $_ -like '*WindowsPowerShell*' }
    $env:PSModulePath = $NewPSModulePath -join ';'
}

# Run Win11Debloat script with the provided arguments
$debloatScriptPath = Join-Path $tempWorkPath 'Win11Debloat.ps1'
$exitCode = 0
$debloatProcess = $null
try {
    $debloatProcess = Start-Process powershell.exe -WindowStyle $windowStyle -PassThru -ArgumentList "-executionpolicy bypass -File `"$debloatScriptPath`" $arguments" -Verb RunAs -ErrorAction Stop
}
catch {
    $exitCode = 1
    Write-Error (get_launcher_text -key 'LaunchFailed' -format_args @($_))
}

# Wait for the process to finish before continuing
if ($null -ne $debloatProcess) {
    $debloatProcess.WaitForExit()
    $exitCode = $debloatProcess.ExitCode
}

# Remove all remaining script files, except for configs, logs and backups
if (Test-Path $tempWorkPath) {
    Write-Output ""
    Write-Output (get_launcher_text -key 'Cleanup')

    # Cleanup, remove Win11Debloat directory
    Get-ChildItem -LiteralPath $tempWorkPath -Force |
        Where-Object { $_.Name -notin @('Config', 'ConfigOld', 'Logs', 'Backups', 'LastUsedSettings.json', 'Preferences.json') } |
        ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop }
}

Write-Output ""
Exit $exitCode
