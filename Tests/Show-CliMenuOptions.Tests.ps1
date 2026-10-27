BeforeAll {
    . (Join-Path $PSScriptRoot '..\Scripts\FileIO\Import-JsonFile.ps1')
    . (Join-Path $PSScriptRoot '..\Scripts\FileIO\Import-LanguageFile.ps1')
    $script:LanguagesPath = Join-Path $PSScriptRoot '..\Config\Languages'
    $script:Lang = Import-LanguageFile -LanguageCode 'en-US'
    function Get-UserName { 'Alice' }
    . (Join-Path $PSScriptRoot '..\Scripts\Helpers\Get-TargetUserForAppRemoval.ps1')
    . (Join-Path $PSScriptRoot '..\Scripts\Helpers\Get-FriendlyTargetUserName.ps1')
    function Generate-AppsList { @() }
    function Add-Parameter { param($Name, $Value) }
    function Save-Settings {}
    function Import-Settings { param($filePath, $expectedVersion) }
    function Wait-ForKeyPress {}
    function Show-AppSelectionWindow { $false }

    . (Join-Path $PSScriptRoot '..\Scripts\CLI\Write-CliHeader.ps1')
    . (Join-Path $PSScriptRoot '..\Scripts\CLI\Write-PendingChanges.ps1')
    . (Join-Path $PSScriptRoot '..\Scripts\CLI\Show-CliAppRemoval.ps1')
    . (Join-Path $PSScriptRoot '..\Scripts\CLI\Show-CliDefaultModeAppRemovalOptions.ps1')
    . (Join-Path $PSScriptRoot '..\Scripts\CLI\Show-CliDefaultModeOptions.ps1')
    . (Join-Path $PSScriptRoot '..\Scripts\CLI\Show-CliLastUsedSettings.ps1')
    . (Join-Path $PSScriptRoot '..\Scripts\CLI\Show-CliMenuOptions.ps1')
}

Describe 'Show-CliMenuOptions' {
    BeforeEach {
        $script:Params = @{}
        $script:ControlParams = @('WhatIf', 'Silent')
        $script:Features = @{ DisableTelemetry = [PSCustomObject]@{ Label = 'Disable telemetry' }; CreateRestorePoint = [PSCustomObject]@{ Label = 'Create restore point' } }
        $script:SelectedApps = @('One.App', 'Two.App')
        $script:SavedSettingsFilePath = 'C:\Settings\LastUsedSettings.json'
        $script:DefaultSettingsFilePath = 'C:\Settings\DefaultSettings.json'
        $script:InputQueue = @()
        $script:InputIndex = 0
        $script:Silent = $false
        $script:RunDefaults = $false
        $script:RunDefaultsLite = $false
        Mock Clear-Host {}
        Mock Write-Host {}
        Mock Write-Output {}
        Mock Read-Host { $script:InputQueue[$script:InputIndex++] }
        Mock Get-UserName { 'Alice' }
        Mock Generate-AppsList { @('One.App', 'Two.App') }
        Mock Add-Parameter {}
        Mock Save-Settings {}
        Mock Import-Settings {}
        Mock Show-AppSelectionWindow { $true }
        Mock Test-Path { $true }
    }

    It 'prints user or Sysprep context in the CLI header' {
        $script:Params = @{}
        Write-CliHeader -title 'Menu'
        $script:Params = @{ Sysprep = $true }
        Write-CliHeader -title 'Menu'

        Should -Invoke Write-Host -Times 6 -Exactly
        Should -Invoke Get-UserName -Times 1 -Exactly
    }

    It 'summarizes selected features and app removal before confirmation' {
        $script:Params = @{ DisableTelemetry = $true; RemoveApps = $true; Apps = 'Default' }
        $script:ControlParams = @('WhatIf', 'Silent', 'Apps')
        $script:InputQueue = @('')

        Write-PendingChanges

        Should -Invoke Generate-AppsList -Times 1 -Exactly
        Should -Invoke Read-Host -Times 1 -Exactly
        Should -Invoke Write-Output -Times 2 -ParameterFilter { $InputObject -like '- *' }
    }

    It 'returns the saved-settings menu option only when the file is available' {
        $script:InputQueue = @('3')

        Show-CliMenuOptions | Should -Be '3'
        Should -Invoke Test-Path -Times 2 -Exactly
    }

    It 're-prompts after a cancelled manual app selection and accepts no removal' {
        Mock Show-AppSelectionWindow { $false }
        $script:InputQueue = @('2', 'n')

        Show-CliDefaultModeAppRemovalOptions | Should -Be 'n'
        Should -Invoke Show-AppSelectionWindow -Times 1 -Exactly
        Should -Invoke Read-Host -Times 2 -Exactly
    }

    It 'records selected app removal and skips confirmation in silent mode' {
        $script:Silent = $true

        Show-CliAppRemoval

        Should -Invoke Add-Parameter -Times 1 -Exactly -ParameterFilter { $Name -eq 'RemoveApps' }
        Should -Invoke Add-Parameter -Times 1 -Exactly -ParameterFilter { $Name -eq 'Apps' -and $Value -eq 'One.App,Two.App' }
        Should -Invoke Save-Settings -Times 1 -Exactly
        Should -Invoke Read-Host -Times 0 -Exactly
    }

    It 'loads saved settings without prompting in silent mode' {
        $script:Silent = $true

        Show-CliLastUsedSettings

        Should -Invoke Import-Settings -Times 1 -Exactly -ParameterFilter { $filePath -eq $script:SavedSettingsFilePath -and $expectedVersion -eq '1.0' }
        Should -Invoke Read-Host -Times 0 -Exactly
    }

    It 'applies default app-removal parameters for the RunDefaults switch' {
        $script:RunDefaults = $true
        $script:Silent = $true

        Show-CliDefaultModeOptions

        Should -Invoke Add-Parameter -Times 1 -Exactly -ParameterFilter { $Name -eq 'RemoveApps' }
        Should -Invoke Add-Parameter -Times 1 -Exactly -ParameterFilter { $Name -eq 'Apps' -and $Value -eq 'Default' }
        Should -Invoke Import-Settings -Times 1 -Exactly
    }
}

Describe 'Korean CLI app-removal scope regression' {
    BeforeAll {
        # Use the real parameter and target helpers; only the mutation backends are mocked.
        . (Join-Path $PSScriptRoot '..\Scripts\Helpers\Add-Parameter.ps1')
        . (Join-Path $PSScriptRoot '..\Scripts\AppRemoval\Remove-SelectedApps.ps1')
    }

    BeforeEach {
        $script:Lang = Import-LanguageFile -LanguageCode 'ko-KR'
        $script:Params = @{}
        $script:SelectedApps = @('One.App', 'Two.App')
        $script:Silent = $false
        $script:CliLines = [System.Collections.Generic.List[string]]::new()
        $script:TextBeforeConfirmation = @()
        $script:AppRemovalFailures = 0
        $script:WingetDeferredRemovals = @{}
        $script:CancelRequested = $false
        $script:ApplySubStepCallback = $null
        Mock Write-CliHeader {}
        Mock Write-Host {}
        Mock Write-Output { param($InputObject) $script:CliLines.Add([string]$InputObject) }
        Mock Read-Host { $script:TextBeforeConfirmation = $script:CliLines.ToArray(); 'n' }
        Mock Save-Settings {}
        Mock Show-AppSelectionWindow { $true }
        Mock Get-AppRemovalMethod { 'Appx' }
        Mock Remove-AppxApp { $true }
        Mock Remove-WinGetApp { throw 'This test must never invoke the WinGet backend.' }
    }

    AfterEach {
        $script:Lang = Import-LanguageFile -LanguageCode 'en-US'
    }

    It 'names the actual Korean target in the default-mode prompt for <Case>' -ForEach @(
        @{ Case = 'current user'; InputParams = @{ AppRemovalTarget = 'CurrentUser' }; ExpectedTarget = 'CurrentUser'; ExpectedPrompt = '앱을 제거하시겠습니까? 제거 대상: 현재 사용자 (n/1/2)' }
        @{ Case = 'explicit all users'; InputParams = @{ AppRemovalTarget = 'AllUsers' }; ExpectedTarget = 'AllUsers'; ExpectedPrompt = '앱을 제거하시겠습니까? 제거 대상: 모든 사용자 (n/1/2)' }
        @{ Case = 'default all users'; InputParams = @{}; ExpectedTarget = 'AllUsers'; ExpectedPrompt = '앱을 제거하시겠습니까? 제거 대상: 모든 사용자 (n/1/2)' }
        @{ Case = 'named user'; InputParams = @{ AppRemovalTarget = 'Alice' }; ExpectedTarget = 'Alice'; ExpectedPrompt = '앱을 제거하시겠습니까? 제거 대상: 사용자 Alice (n/1/2)' }
    ) {
        $script:Params = $InputParams.Clone()

        Show-CliDefaultModeAppRemovalOptions | Should -Be 'n'

        Should -Invoke Read-Host -Times 1 -Exactly -ParameterFilter { $Prompt -ceq $ExpectedPrompt }
        Get-TargetUserForAppRemoval | Should -BeExactly $ExpectedTarget
        $script:Params.Count | Should -Be $InputParams.Count
        Should -Invoke Show-AppSelectionWindow -Times 0 -Exactly
        Should -Invoke Save-Settings -Times 0 -Exactly
        Should -Invoke Remove-AppxApp -Times 0 -Exactly
        Should -Invoke Remove-WinGetApp -Times 0 -Exactly
    }

    It 'keeps the Korean manual confirmation scope-neutral and routes <Case> to the same target' -ForEach @(
        @{ Case = 'current user'; InputParams = @{ AppRemovalTarget = 'CurrentUser' }; ExpectedTarget = 'CurrentUser'; WrongScope = '모든 사용자' }
        @{ Case = 'explicit all users'; InputParams = @{ AppRemovalTarget = 'AllUsers' }; ExpectedTarget = 'AllUsers'; WrongScope = '현재 사용자' }
        @{ Case = 'default all users'; InputParams = @{}; ExpectedTarget = 'AllUsers'; WrongScope = '현재 사용자' }
    ) {
        $script:Params = $InputParams.Clone()

        Show-CliAppRemoval

        $script:TextBeforeConfirmation | Should -Contain '제거할 앱 2개를 선택했습니다.'
        $script:TextBeforeConfirmation | Should -Contain '선택한 앱을 제거하려면 Enter 키를 누르세요. 취소하려면 Ctrl+C를 누르세요.'
        ($script:TextBeforeConfirmation -join "`n") | Should -Not -Match ([regex]::Escape($WrongScope))
        $script:Params.RemoveApps | Should -BeTrue
        $script:Params.Apps | Should -BeExactly 'One.App,Two.App'
        $script:Params.ContainsKey('AppRemovalTarget') | Should -Be $InputParams.ContainsKey('AppRemovalTarget')
        Get-TargetUserForAppRemoval | Should -BeExactly $ExpectedTarget
        Should -Invoke Read-Host -Times 1 -Exactly
        Should -Invoke Save-Settings -Times 1 -Exactly
        # Selecting/confirming only queues settings. It must not uninstall anything itself.
        Should -Invoke Remove-AppxApp -Times 0 -Exactly
        Should -Invoke Remove-WinGetApp -Times 0 -Exactly

        # Exercise the real removal dispatcher with inert backends to verify the queued scope.
        Remove-SelectedApps -appsList ($script:Params.Apps -split ',') | Should -BeTrue
        Should -Invoke Remove-AppxApp -Times 1 -Exactly -ParameterFilter { $app -eq 'One.App' -and $targetUser -ceq $ExpectedTarget }
        Should -Invoke Remove-AppxApp -Times 1 -Exactly -ParameterFilter { $app -eq 'Two.App' -and $targetUser -ceq $ExpectedTarget }
        Should -Invoke Remove-AppxApp -Times 2 -Exactly
        Should -Invoke Remove-WinGetApp -Times 0 -Exactly
    }

    It 'does not queue, save or confirm a cancelled Korean manual selection' {
        $script:Params = @{ AppRemovalTarget = 'CurrentUser' }
        Mock Show-AppSelectionWindow { $false }

        Show-CliAppRemoval

        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -ceq '선택을 취소했습니다. 제거된 앱이 없습니다.' }
        $script:Params.Count | Should -Be 1
        Get-TargetUserForAppRemoval | Should -BeExactly 'CurrentUser'
        Should -Invoke Save-Settings -Times 0 -Exactly
        Should -Invoke Read-Host -Times 0 -Exactly
        Should -Invoke Remove-AppxApp -Times 0 -Exactly
        Should -Invoke Remove-WinGetApp -Times 0 -Exactly
    }

    It 'retains CurrentUser and queues selected IDs without prompting in Korean silent mode' {
        $script:Params = @{ AppRemovalTarget = 'CurrentUser' }
        $script:Silent = $true

        Show-CliAppRemoval

        $script:Params.RemoveApps | Should -BeTrue
        $script:Params.Apps | Should -BeExactly 'One.App,Two.App'
        Get-TargetUserForAppRemoval | Should -BeExactly 'CurrentUser'
        ($script:CliLines -join "`n") | Should -Not -Match 'Enter|Ctrl\+C|모든 사용자'
        Should -Invoke Save-Settings -Times 1 -Exactly
        Should -Invoke Read-Host -Times 0 -Exactly
        Should -Invoke Remove-AppxApp -Times 0 -Exactly
        Should -Invoke Remove-WinGetApp -Times 0 -Exactly
    }
}
