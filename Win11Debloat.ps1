[CmdletBinding(SupportsShouldProcess)]
param (
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
    [switch]$DisableStorageSense,
    [switch]$DisableUpdateASAP,
    [switch]$PreventUpdateAutoReboot,
    [switch]$DisableDeliveryOptimization,
    [switch]$DisableDeviceAutoAppDownload,
    [switch]$DisableBing,
    [switch]$DisableNotifications,
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

# Bootstrap failures cannot depend on the language catalogs they are diagnosing.
if ($ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage') {
    Write-Error 'PowerShell execution is restricted by security policies. / 보안 정책으로 PowerShell 실행이 제한되어 있습니다.'
    Exit 1
}

# Define script-level variables & paths
$script:Version = "2026.08.24"
$configPath = Join-Path $PSScriptRoot 'Config'
# Deployment environments such as SCCM task sequences may not define LOCALAPPDATA.
if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
    $script:UserDataPath = $PSScriptRoot
}
else {
    $script:UserDataPath = Join-Path $env:LOCALAPPDATA 'Win11Debloat'
}
$script:LogsPath = Join-Path $script:UserDataPath 'Logs'
$schemasPath = Join-Path $PSScriptRoot 'Schemas'
$scriptsPath = Join-Path $PSScriptRoot 'Scripts'

$script:AppsListFilePath = Join-Path $configPath 'Apps.json'
$script:DefaultSettingsFilePath = Join-Path $configPath 'DefaultSettings.json'
$script:FeaturesFilePath = Join-Path $configPath 'Features.json'
$script:SavedSettingsFilePath = Join-Path $script:UserDataPath 'LastUsedSettings.json'
$script:UiPreferencesFilePath = Join-Path $script:UserDataPath 'Preferences.json'
$script:LanguagesPath = Join-Path $configPath 'Languages'
$script:DefaultLanguagePath = Join-Path $script:LanguagesPath 'en-US'
$script:DefaultLogPath = Join-Path $script:LogsPath 'Win11Debloat.log'
$script:RegfilesPath = Join-Path $PSScriptRoot 'Regfiles'
$script:RegistryBackupsPath = Join-Path $script:UserDataPath 'Backups'
$script:AssetsPath = Join-Path $PSScriptRoot 'Assets'
$script:AppSelectionSchema = Join-Path $schemasPath 'AppSelectionWindow.xaml'
$script:MainWindowSchema = Join-Path $schemasPath 'MainWindow.xaml'
$script:MessageBoxSchema = Join-Path $schemasPath 'MessageBox.xaml'
$script:AboutWindowSchema = Join-Path $schemasPath 'AboutWindow.xaml'
$script:ApplyChangesWindowSchema = Join-Path $schemasPath 'ApplyChangesWindow.xaml'
$script:SharedStylesSchema = Join-Path $schemasPath 'SharedStyles.xaml'
$script:BubbleHintSchema = Join-Path $schemasPath 'BubbleHint.xaml'
$script:ImportExportConfigSchema = Join-Path $schemasPath 'ImportExportConfigWindow.xaml'
$script:RestoreBackupWindowSchema = Join-Path $schemasPath 'RestoreBackupWindow.xaml'
$script:LoadAppsDetailsScriptPath = Join-Path (Join-Path $scriptsPath 'FileIO') 'Import-AppDetailsFromJson.ps1'
$script:TestAppInWingetListScriptPath = Join-Path (Join-Path $scriptsPath 'AppRemoval') 'Test-AppInWingetList.ps1'
$script:ImportLanguageFileScriptPath = Join-Path (Join-Path $scriptsPath 'FileIO') 'Import-LanguageFile.ps1'

# Startup notices must not dot-source downloaded helper scripts before the existing
# Mark-of-the-Web handling below. Read only JSON here; full localization loads later.
$startup_language_code = $Language
if (-not $startup_language_code -and (Test-Path -LiteralPath $script:UiPreferencesFilePath)) {
    try {
        $startup_preferences = Get-Content -LiteralPath $script:UiPreferencesFilePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $startup_language_code = $startup_preferences.Language
    }
    catch { }
}
if (-not $startup_language_code -or $startup_language_code -eq 'Auto') {
    $startup_language_code = [System.Globalization.CultureInfo]::CurrentUICulture.Name
}
if ([string]::IsNullOrWhiteSpace($startup_language_code) -or $startup_language_code -notmatch '^[a-zA-Z]{2,3}(-[a-zA-Z0-9]{2,8})*$') {
    $startup_language_code = 'en-US'
}
$startup_language_path = Join-Path $script:LanguagesPath $startup_language_code
if (-not (Test-Path -LiteralPath $startup_language_path -PathType Container)) {
    $startup_prefix = ($startup_language_code -split '-')[0]
    $startup_match = Get-ChildItem -LiteralPath $script:LanguagesPath -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "$startup_prefix-*" } | Select-Object -First 1
    if ($startup_match) { $startup_language_path = $startup_match.FullName }
}
$script:startup_catalogs = @()
foreach ($startup_path in @($startup_language_path, $script:DefaultLanguagePath)) {
    try {
        $script:startup_catalogs += Get-Content -LiteralPath (Join-Path $startup_path 'Chrome.json') -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    }
    catch { }
}
function get_startup_text {
    param([string]$Key, [object[]]$FormatArgs)
    foreach ($startup_catalog in $script:startup_catalogs) {
        if ($startup_catalog.PSObject.Properties[$Key]) {
            $startup_text = [string]$startup_catalog.$Key
            if ($FormatArgs -and $FormatArgs.Count) {
                try { return $startup_text -f $FormatArgs } catch { return $startup_text }
            }
            return $startup_text
        }
    }
    return "Win11Debloat startup / 시작 안내: $Key. Check the complete archive / 전체 압축 파일을 확인하세요."
}

# Win11Debloat depends on Windows PowerShell 5.1 cmdlets (the Appx module's Get-AppxPackage /
# Remove-AppxPackage, and Get-ComputerRestorePoint) that do not load in PowerShell 7 (pwsh), where the
# Appx module fails with "Operation is not supported on this platform" (0x80131539). Without this guard
# the run continues and silently fails to remove any apps while still reporting success. See issue #675.
if ($PSVersionTable.PSEdition -eq 'Core') {
    Write-Host (get_startup_text -Key 'StartupRequiresWindowsPowerShell' -FormatArgs @($PSVersionTable.PSVersion)) -ForegroundColor Red
    Write-Host (get_startup_text -Key 'StartupCoreUnsupported') -ForegroundColor Red
    Write-Host (get_startup_text -Key 'StartupUseWindowsPowerShell') -ForegroundColor Yellow
    exit 1
}

# Check if script is running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# If script is not running as administrator ask user if they want to allow it
if (-not $isAdmin) {
    Write-Host (get_startup_text -Key 'StartupRequiresAdmin') -ForegroundColor Red

    $choice = Read-Host (get_startup_text -Key 'StartupElevatePrompt')

    if ($choice -match '^[Yy]$') {
        # Win32-safe escaping for arguments to pass to elevated process
        function Format-ElevatedArg([string]$Value) {
            $escaped = $Value -replace '(\\*)"', '$1$1\"'
            $escaped = $escaped -replace '(\\+)$', '$1$1'
            return '"' + $escaped + '"'
        }

        $elevatedArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Format-ElevatedArg $PSCommandPath))

        foreach ($paramName in $PSBoundParameters.Keys) {
            $paramValue = $PSBoundParameters[$paramName]

            if ($paramValue -is [System.Management.Automation.SwitchParameter]) {
                if ($paramValue.IsPresent) {
                    $elevatedArgs += "-$paramName"
                }
            }
            else {
                $elevatedArgs += "-$paramName"
                $elevatedArgs += (Format-ElevatedArg $paramValue)
            }
        }

        if ($MyInvocation.UnboundArguments.Count -gt 0) {
            foreach ($unboundArg in $MyInvocation.UnboundArguments) {
                $elevatedArgs += (Format-ElevatedArg "$unboundArg")
            }
        }

        try {
            Start-Process powershell -ArgumentList $elevatedArgs -Verb RunAs -ErrorAction Stop
        }
        catch {
            Write-Error (get_startup_text -Key 'StartupElevateFailed' -FormatArgs @($_))
            Exit 1
        }

        Exit 0
    }

    Exit 1
}

$script:ControlParams = 'WhatIf', 'Confirm', 'Verbose', 'Debug', 'LogPath', 'Language', 'Silent', 'Sysprep', 'User', 'SkipExplorerRestart', 'SkipRegistryBackup', 'RunDefaults', 'RunDefaultsLite', 'RunSavedSettings', 'Config', 'CLI', 'AppRemovalTarget'

# Script-level variables for GUI elements
$script:GuiWindow = $null
$script:CancelRequested = $false
$script:ApplyProgressCallback = $null
$script:ApplySubStepCallback = $null
$script:RegistryImportFailures = 0
$script:AppRemovalFailures = 0
$script:AppRemovalVerificationUnavailable = $false


Clear-Host

# Ensure required Windows command paths are present in PATH for this session.
$system32Path = "$env:SystemRoot\System32"
if ($env:PATH -notmatch "(?i)(^|;)$([regex]::Escape($system32Path))(?=;|$)") {
    $env:PATH = "$env:SystemRoot\System32;$env:SystemRoot;" + $env:PATH
    Write-Warning (get_startup_text -Key 'StartupSystemPathAdded')
}

# Display ASCII art launch logo in CLI
Write-Host ""
Write-Host ""
Write-Host "                   " -NoNewline; Write-Host "      ^" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "     / \" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "    /   \" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "   /     \" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "  / ===== \" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "  |" -ForegroundColor Blue -NoNewline; Write-Host "  ---  " -ForegroundColor White -NoNewline; Write-Host "|" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "  |" -ForegroundColor Blue -NoNewline; Write-Host " ( O ) " -ForegroundColor DarkCyan -NoNewline; Write-Host "|" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "  |" -ForegroundColor Blue -NoNewline; Write-Host "  ---  " -ForegroundColor White -NoNewline; Write-Host "|" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "  |       |" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host " /|       |\" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "/ |       | \" -ForegroundColor Blue
Write-Host "                   " -NoNewline; Write-Host "  |  " -ForegroundColor DarkGray -NoNewline; Write-Host "'''" -ForegroundColor Red -NoNewline; Write-Host "  |" -ForegroundColor DarkGray -NoNewline; Write-Host "    *" -ForegroundColor Yellow
Write-Host "                   " -NoNewline; Write-Host "    (" -ForegroundColor Yellow -NoNewline; Write-Host "'''" -ForegroundColor Red -NoNewline; Write-Host ") " -ForegroundColor Yellow -NoNewline; Write-Host "   *  *" -ForegroundColor DarkYellow
Write-Host "                   " -NoNewline; Write-Host "    ( " -ForegroundColor DarkYellow -NoNewline; Write-Host "'" -ForegroundColor Red -NoNewline; Write-Host " )   " -ForegroundColor DarkYellow -NoNewline; Write-Host "*" -ForegroundColor Yellow
Write-Host ""
Write-Host (get_startup_text -Key 'StartupLaunching') -ForegroundColor White
Write-Host (get_startup_text -Key 'StartupKeepOpen') -ForegroundColor DarkGray
Write-Host ""
Write-Host ""

# Log script output to 'Win11Debloat.log' at the specified path
if ($LogPath -and (Test-Path $LogPath)) {
    Start-Transcript -Path (Join-Path $LogPath 'Win11Debloat.log') -Append -IncludeInvocationHeader -Force | Out-Null
}
else {
    Start-Transcript -Path $script:DefaultLogPath -Append -IncludeInvocationHeader -Force | Out-Null
}

# When Group Policy overrides Run.bat's Process-scope Bypass, marked PowerShell source files
# can prompt as they are dot-sourced. Outside -WhatIf, remove Mark-of-the-Web only from marked
# .ps1, .psm1, and .psd1 files under Scripts; leave all other downloaded files untouched.
# See issue #720.
if (-not $WhatIfPreference) {
    $gpoExecutionPolicySet = (Get-ExecutionPolicy -Scope MachinePolicy) -ne 'Undefined' -or
        (Get-ExecutionPolicy -Scope UserPolicy) -ne 'Undefined'

    if ($gpoExecutionPolicySet) {
        $markedScriptFiles = @(Get-ChildItem -LiteralPath $scriptsPath -Recurse -File |
            Where-Object { $_.Extension -in '.ps1', '.psm1', '.psd1' } |
            Where-Object {
                Get-Item -LiteralPath $_.FullName -Stream * -ErrorAction SilentlyContinue |
                    Where-Object { $_.Stream -eq 'Zone.Identifier' }
            })

        if ($markedScriptFiles.Count -gt 0) {
            Write-Host (get_startup_text -Key 'StartupUnblocking' -FormatArgs @($markedScriptFiles.Count))
            $unblockErrors = @()
            $markedScriptFiles | Unblock-File -ErrorAction SilentlyContinue -ErrorVariable +unblockErrors

            if ($unblockErrors.Count -gt 0) {
                Write-Warning (get_startup_text -Key 'StartupUnblockFailed' -FormatArgs @($unblockErrors.Count))
            }
            else {
                Write-Host (get_startup_text -Key 'StartupUnblockDone')
            }
        }
    }
}

# Check if the device is domain-joined and warn the user (Group Policy may override changes)
try {
    $computerSystem = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    if ($null -ne $computerSystem -and $computerSystem.PartOfDomain) {
        Write-Warning (get_startup_text -Key 'StartupDomainWarning')
    }
}
catch { }

# Check if script has all required files
if (-not ((Test-Path $script:DefaultSettingsFilePath) -and (Test-Path $script:AppsListFilePath) -and (Test-Path $script:RegfilesPath) -and (Test-Path $script:AssetsPath) -and (Test-Path $script:AppSelectionSchema) -and (Test-Path $script:ApplyChangesWindowSchema) -and (Test-Path $script:SharedStylesSchema) -and (Test-Path $script:BubbleHintSchema) -and (Test-Path $script:RestoreBackupWindowSchema) -and (Test-Path $script:FeaturesFilePath) -and (Test-Path $script:DefaultLanguagePath))) {
    Write-Error (get_startup_text -Key 'StartupMissingFiles')
    Write-Output (get_startup_text -Key 'CliExitPrompt')
    $null = [System.Console]::ReadKey()
    Exit 1
}

# Load feature info from file
$script:Features = @{}
try {
    $featuresData = Get-Content -Path $script:FeaturesFilePath -Raw | ConvertFrom-Json
    foreach ($feature in $featuresData.Features) {
        if ([string]::IsNullOrWhiteSpace([string]$feature.FeatureId) -or [string]::IsNullOrWhiteSpace([string]$feature.Label) -or [string]::IsNullOrWhiteSpace([string]$feature.ApplyText)) {
            Write-Warning (get_startup_text -Key 'StartupInvalidFeature' -FormatArgs @($feature.FeatureId))
            continue
        }
        $script:Features[$feature.FeatureId] = $feature
    }
}
catch {
    Write-Error (get_startup_text -Key 'StartupFeaturesLoadFailed')
    Write-Output (get_startup_text -Key 'CliExitPrompt')
    $null = [System.Console]::ReadKey()
    Exit 1
}

# Check if WinGet is installed & if it is, check if the version is at least v1.4
try {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $script:WingetInstalled = $true
    }
    else {
        $script:WingetInstalled = $false
    }
}
catch {
    Write-Error (get_startup_text -Key 'StartupWingetCheckFailed' -FormatArgs @($_))
    $script:WingetInstalled = $false
}

# Show WinGet warning that requires user confirmation, Suppress confirmation if Silent parameter was passed
if (-not $script:WingetInstalled -and -not $Silent) {
    Write-Warning (get_startup_text -Key 'StartupWingetWarning')
    Write-Output ""
    Write-Output (get_startup_text -Key 'StartupContinueAnyway')
    $null = [System.Console]::ReadKey()
}



##################################################################################################################
#                                                                                                                #
#                                                FUNCTION IMPORTS                                                #
#                                                                                                                #
##################################################################################################################

# App removal functions
. "$PSScriptRoot/Scripts/AppRemoval/Invoke-ForceRemoveEdge.ps1"
. "$PSScriptRoot/Scripts/AppRemoval/Remove-SelectedApps.ps1"
. "$PSScriptRoot/Scripts/AppRemoval/Get-WingetInstalledApps.ps1"
. "$PSScriptRoot/Scripts/AppRemoval/Test-AppInWingetList.ps1"

# CLI functions
. "$PSScriptRoot/Scripts/CLI/Wait-ForKeyPress.ps1"
. "$PSScriptRoot/Scripts/CLI/Show-CliLastUsedSettings.ps1"
. "$PSScriptRoot/Scripts/CLI/Show-CliDefaultModeAppRemovalOptions.ps1"
. "$PSScriptRoot/Scripts/CLI/Show-CliDefaultModeOptions.ps1"
. "$PSScriptRoot/Scripts/CLI/Show-CliAppRemoval.ps1"
. "$PSScriptRoot/Scripts/CLI/Show-CliMenuOptions.ps1"
. "$PSScriptRoot/Scripts/CLI/Write-PendingChanges.ps1"
. "$PSScriptRoot/Scripts/CLI/Write-CliHeader.ps1"

# Features functions
. "$PSScriptRoot/Scripts/Features/Get-CurrentTweakState.ps1"
. "$PSScriptRoot/Scripts/Features/Invoke-Changes.ps1"
. "$PSScriptRoot/Scripts/Features/Invoke-SystemRestorePoint.ps1"
. "$PSScriptRoot/Scripts/Features/Backup-RegistryFeatureSelection.ps1"
. "$PSScriptRoot/Scripts/Features/Backup-RegistrySnapshotCapture.ps1"
. "$PSScriptRoot/Scripts/Features/Backup-RegistryState.ps1"
. "$PSScriptRoot/Scripts/Features/Registry-BackupValidation.ps1"
. "$PSScriptRoot/Scripts/Features/Restore-RegistryApplyState.ps1"
. "$PSScriptRoot/Scripts/Features/Restore-RegistryBackup.ps1"
. "$PSScriptRoot/Scripts/Features/Set-StoreSearchSuggestions.ps1"
. "$PSScriptRoot/Scripts/Features/Telemetry-ScheduledTasks.ps1"
. "$PSScriptRoot/Scripts/Features/Windows-OptionalFeatures.ps1"
. "$PSScriptRoot/Scripts/Features/Import-RegistryFile.ps1"
. "$PSScriptRoot/Scripts/Features/Replace-StartMenu.ps1"
. "$PSScriptRoot/Scripts/Features/Invoke-RestartExplorer.ps1"

# File I/O functions
. "$PSScriptRoot/Scripts/FileIO/Import-JsonFile.ps1"
. "$PSScriptRoot/Scripts/FileIO/Import-LanguageFile.ps1"
. "$PSScriptRoot/Scripts/FileIO/Save-ToFile.ps1"
. "$PSScriptRoot/Scripts/FileIO/Save-Settings.ps1"
. "$PSScriptRoot/Scripts/FileIO/Import-Settings.ps1"
. "$PSScriptRoot/Scripts/FileIO/Get-ValidatedAppList.ps1"
. "$PSScriptRoot/Scripts/FileIO/Import-AppsFromFile.ps1"
. "$PSScriptRoot/Scripts/FileIO/Import-AppDetailsFromJson.ps1"
. "$PSScriptRoot/Scripts/FileIO/Import-AppPresetsFromJson.ps1"

# GUI functions
. "$PSScriptRoot/Scripts/GUI/Ui-Preferences.ps1"
. "$PSScriptRoot/Scripts/GUI/Get-SystemUsesDarkMode.ps1"
. "$PSScriptRoot/Scripts/GUI/MainWindow-Localization.ps1"
. "$PSScriptRoot/Scripts/GUI/Show-SettingsDialog.ps1"
. "$PSScriptRoot/Scripts/GUI/Set-WindowThemeResources.ps1"
. "$PSScriptRoot/Scripts/GUI/Attach-ShiftClickBehavior.ps1"
. "$PSScriptRoot/Scripts/GUI/Apply-SettingsToUiControls.ps1"
. "$PSScriptRoot/Scripts/GUI/Show-MessageBox.ps1"
. "$PSScriptRoot/Scripts/GUI/Show-ImportExportConfigWindow.ps1"
. "$PSScriptRoot/Scripts/GUI/Show-ApplyModal.ps1"
. "$PSScriptRoot/Scripts/GUI/Show-AppSelectionWindow.ps1"
. "$PSScriptRoot/Scripts/GUI/Show-RestoreBackupWindow.ps1"
. "$PSScriptRoot/Scripts/GUI/Restore-BackupDialogFeatureLists.ps1"
. "$PSScriptRoot/Scripts/GUI/Show-RestoreBackupDialog.ps1"
. "$PSScriptRoot/Scripts/GUI/MainWindow-WindowChrome.ps1"
. "$PSScriptRoot/Scripts/GUI/MainWindow-AppSelection.ps1"
. "$PSScriptRoot/Scripts/GUI/MainWindow-TweaksBuilder.ps1"
. "$PSScriptRoot/Scripts/GUI/MainWindow-Navigation.ps1"
. "$PSScriptRoot/Scripts/GUI/MainWindow-Deployment.ps1"
. "$PSScriptRoot/Scripts/GUI/Show-MainWindow.ps1"
. "$PSScriptRoot/Scripts/GUI/Show-AboutDialog.ps1"
. "$PSScriptRoot/Scripts/GUI/Show-Bubble.ps1"

# Helper functions
. "$PSScriptRoot/Scripts/Helpers/Add-Parameter.ps1"
. "$PSScriptRoot/Scripts/Helpers/Resolve-UserProfilePath.ps1"
. "$PSScriptRoot/Scripts/Helpers/User-HiveHelpers.ps1"
. "$PSScriptRoot/Scripts/Helpers/Test-UserProfileExists.ps1"
. "$PSScriptRoot/Scripts/Helpers/Test-ModernStandbySupport.ps1"
. "$PSScriptRoot/Scripts/Helpers/Generate-AppsList.ps1"
. "$PSScriptRoot/Scripts/Helpers/Get-FriendlyRegistryBackupTarget.ps1"
. "$PSScriptRoot/Scripts/Helpers/Get-FriendlyTargetUserName.ps1"
. "$PSScriptRoot/Scripts/Helpers/Get-RebootFeatureLabels.ps1"
. "$PSScriptRoot/Scripts/Helpers/Windows-BuildHelpers.ps1"
. "$PSScriptRoot/Scripts/Helpers/Import-ConfigToParams.ps1"
. "$PSScriptRoot/Scripts/Helpers/Test-ConfigConsistency.ps1"
. "$PSScriptRoot/Scripts/Helpers/Get-TargetUserForAppRemoval.ps1"
. "$PSScriptRoot/Scripts/Helpers/Get-RegFileOperations.ps1"
. "$PSScriptRoot/Scripts/Helpers/Test-TargetUserName.ps1"
. "$PSScriptRoot/Scripts/Helpers/Get-UserDirectory.ps1"
. "$PSScriptRoot/Scripts/Helpers/Get-UserName.ps1"
. "$PSScriptRoot/Scripts/Helpers/Registry-PathHelpers.ps1"
. "$PSScriptRoot/Scripts/Helpers/Apply-RegistryRegFile.ps1"
. "$PSScriptRoot/Scripts/Helpers/Confirm-UnsafeAppRemoval.ps1"

# Threading functions
. "$PSScriptRoot/Scripts/Threading/Invoke-DoEvents.ps1"
. "$PSScriptRoot/Scripts/Threading/Invoke-NonBlocking.ps1"



##################################################################################################################
#                                                                                                                #
#                                                  SCRIPT START                                                  #
#                                                                                                                #
##################################################################################################################



# Get current Windows build version
$WinVersion = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' CurrentBuild

# Explicit -Language takes precedence over saved preferences and the system culture.
Initialize-UiPreferences -Language $Language
if (-not $script:Lang) {
    Write-Error 'Unable to load language files / 언어 파일을 불러오지 못했습니다.'
    Exit 1
}

# Check if the machine supports Modern Standby, this is used to determine if the DisableModernStandbyNetworking option can be used
$script:ModernStandbySupported = Test-ModernStandbySupport

$script:Params = $PSBoundParameters
$script:UndoParams = @{}

# Add default Apps parameter when RemoveApps is requested and Apps was not explicitly provided
if ((-not $script:Params.ContainsKey("Apps")) -and $script:Params.ContainsKey("RemoveApps")) {
    $script:Params.Add('Apps', 'Default')
}

$controlParamsCount = 0

# Count how many control parameters are set, to determine if any changes were selected by the user during runtime
foreach ($Param in $script:ControlParams) {
    if ($script:Params.ContainsKey($Param)) {
        $controlParamsCount++
    }
}

# Hide progress bars for app removal, as they block Win11Debloat's output
if (-not ($script:Params.ContainsKey("Verbose"))) {
    $ProgressPreference = 'SilentlyContinue'
}
else {
    Write-Host (Get-Translation -Key 'CliVerboseEnabled')
    Write-Output ""
    Write-Output (Get-Translation -Key 'CliContinuePrompt')
    $null = [System.Console]::ReadKey()

    $ProgressPreference = 'Continue'
}

if ($script:Params.ContainsKey("Sysprep")) {
    Get-UserDirectory -userName "Default" | Out-Null

    # Exit script if run in Sysprep mode on Windows 10
    if ($WinVersion -lt 22000) {
        Write-Error (Get-Translation -Key 'CliSysprepUnsupported')
        Wait-ForKeyPress -ExitCode 1
    }
}

# Ensure that target user exists, if User or AppRemovalTarget parameter was provided
if ($script:Params.ContainsKey("User")) {
    Get-UserDirectory -userName $script:Params.Item("User") | Out-Null
}
if ($script:Params.ContainsKey("AppRemovalTarget")) {
    $appRemovalTargetValue = $script:Params.Item("AppRemovalTarget")
    # 'AllUsers' / 'CurrentUser' are sentinel scope values, not real usernames - don't resolve them as a profile
    if ($appRemovalTargetValue -notin @('AllUsers', 'CurrentUser')) {
        Get-UserDirectory -userName $appRemovalTargetValue | Out-Null
    }
}

# Remove LastUsedSettings.json file if it exists and is empty
if ((Test-Path $script:SavedSettingsFilePath) -and ([String]::IsNullOrWhiteSpace((Get-content $script:SavedSettingsFilePath)))) {
    Remove-Item -Path $script:SavedSettingsFilePath -Force
}

# Default to CLI mode for deployment-targeted parameters.
$launchInCLI = $CLI -or $script:Params.ContainsKey("User") -or $script:Params.ContainsKey("Sysprep") -or $script:Params.ContainsKey("AppRemovalTarget")

# Change script execution based on provided parameters or user input
if ((-not $script:Params.Count) -or $RunDefaults -or $RunDefaultsLite -or $RunSavedSettings -or $Config -or ($controlParamsCount -eq $script:Params.Count)) {
    if ($RunDefaults -or $RunDefaultsLite) {
        Show-CliDefaultModeOptions
    }
    elseif ($RunSavedSettings) {
        if (-not (Test-Path $script:SavedSettingsFilePath)) {
            Write-CliHeader (Get-Translation -Key 'CliTitleCustom')
            Write-Error (Get-Translation -Key 'CliSavedSettingsMissing')
            Wait-ForKeyPress -ExitCode 1
        }

        Show-CliLastUsedSettings
    }
    elseif ($Config) {
        try {
            Import-ConfigToParams -ConfigPath $Config -CurrentBuild $WinVersion -ExpectedVersion '1.0'
        }
        catch {
            Write-Error "$_"
            Wait-ForKeyPress -ExitCode 1
        }

        if (-not $Silent) {
            Write-CliHeader (Get-Translation -Key 'CliTitleCustom')
            Write-PendingChanges
            Write-CliHeader (Get-Translation -Key 'CliTitleCustom')
        }
    }
    else {
        if ($launchInCLI) {
            $Mode = Show-CliMenuOptions
        }
        else {
            try {
                $result = Show-MainWindow
            
                try {
                    Stop-Transcript
                }
                catch { }

                Exit
            }
            catch {
                Write-Warning (Get-Translation -Key 'CliGuiStartFailed' -FormatArgs @($_.Exception.Message))
                Write-Verbose "GUI Failure details: $($_.Exception.ToString())"
                if (-not $Silent) {
                    Write-Host ""
                    Write-Host (Get-Translation -Key 'CliContinueInConsole')
                    $null = [System.Console]::ReadKey()
                }

                $Mode = Show-CliMenuOptions
            }
        }
    }

    # Add execution parameters based on the mode
    switch ($Mode) {
        # Default mode, loads defaults and app removal options
        '1' { 
            Show-CliDefaultModeOptions
        }

        # App removal, remove apps based on user selection
        '2' {
            Show-CliAppRemoval
        }

        # Load last used options from the "LastUsedSettings.json" file
        '3' {
            Show-CliLastUsedSettings
        }
    }
}
else {
    Write-CliHeader (Get-Translation -Key 'CliTitleConfiguration')
}

# If the number of keys in ControlParams equals the number of keys in Params then no modifications/changes were selected
#  or added by the user, and the script can exit without making any changes.
if (($controlParamsCount -eq $script:Params.Keys.Count) -or ($script:Params.Keys.Count -eq 1 -and ($script:Params.Keys -contains 'CreateRestorePoint' -or $script:Params.Keys -contains 'Apps'))) {
    Write-Output (Get-Translation -Key 'CliNoChanges')
    Wait-ForKeyPress
}

# Execute all selected/provided parameters using the consolidated function
# (This also handles restore point creation if requested)
Invoke-AllChanges

if ($script:CancelRequested) {
    Write-Warning (Get-Translation -Key 'CliExecutionCancelled')
    Wait-ForKeyPress
}

# Restart Explorer process unless running in Sysprep or User context
if (-not ($script:Params.ContainsKey("Sysprep") -or $script:Params.ContainsKey("User"))) {
    Invoke-RestartExplorer
}

Write-Output ""
Write-Output ""
Write-Output ""
Write-Output (Get-Translation -Key 'CliCompleted')

Wait-ForKeyPress
