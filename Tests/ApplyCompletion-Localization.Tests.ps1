# Exercise the real completion branch without loading WPF or invoking any apply action.
BeforeAll {
    . (Join-Path $PSScriptRoot '../Scripts/FileIO/Import-JsonFile.ps1')
    . (Join-Path $PSScriptRoot '../Scripts/FileIO/Import-LanguageFile.ps1')
    $script:LanguagesPath = Join-Path $PSScriptRoot '../Config/Languages'
    $tokens = $null
    $parse_errors = $null
    $apply_ast = [System.Management.Automation.Language.Parser]::ParseFile(
        (Join-Path $PSScriptRoot '../Scripts/GUI/Show-ApplyModal.ps1'), [ref]$tokens, [ref]$parse_errors)
    if ($parse_errors.Count) { throw 'Unable to parse Show-ApplyModal.' }
    $completion_branches = @($apply_ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.IfStatementAst] -and
        $node.Clauses.Count -ge 2 -and
        $node.Clauses[0].Item1.Extent.Text -eq '$script:CancelRequested'
    }, $true))
    if ($completion_branches.Count -ne 1) { throw 'Completion branch contract changed; inspect before testing.' }
    $script:completion_branch = [scriptblock]::Create($completion_branches[0].Extent.Text)
    function Get-RebootFeatureLabels { @() }
}

Describe 'Apply completion localization' {
    BeforeEach {
        $script:Params = @{}
        $script:CancelRequested = $false
        $failureCount = 0
        $appRemovalVerificationUnavailable = $false
        $script:ApplyCompletionTitleEl = [PSCustomObject]@{ Text = '' }
        $script:ApplyCompletionMessageEl = [PSCustomObject]@{ Text = 'initial message' }
        Mock Write-Host {}
        Mock Get-RebootFeatureLabels { @() }
    }

    It 'describes WhatIf as a preview for <Language> with restart option <Restart>' -ForEach @(
        @{ Language = 'en-US'; Restart = $false }
        @{ Language = 'en-US'; Restart = $true }
        @{ Language = 'ko-KR'; Restart = $false }
        @{ Language = 'ko-KR'; Restart = $true }
    ) {
        $script:Lang = Import-LanguageFile -LanguageCode $Language
        $script:Params = @{ WhatIf = $true }
        $InvokeRestartExplorer = $Restart

        & $script:completion_branch

        $script:ApplyCompletionTitleEl.Text | Should -Be (Get-Translation -Key 'ApplyCompletionTitlePreview')
        $script:ApplyCompletionTitleEl.Text | Should -Not -Be 'ApplyCompletionTitlePreview'
        $script:ApplyCompletionMessageEl.Text | Should -Be (Get-Translation -Key 'ApplyCompletionMessagePreview')
        $script:ApplyCompletionMessageEl.Text | Should -Not -Be 'ApplyCompletionMessagePreview'
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter {
            $Object -eq (Get-Translation -Key 'GuiChangesPreviewed')
        }
        Should -Invoke Write-Host -Times 0 -Exactly -ParameterFilter {
            $Object -eq (Get-Translation -Key 'GuiChangesApplied')
        }
        Should -Invoke Get-RebootFeatureLabels -Times 0 -Exactly
    }

    It 'keeps normal success and readiness messages for <Language>' -ForEach @(
        @{ Language = 'en-US' }
        @{ Language = 'ko-KR' }
    ) {
        $script:Lang = Import-LanguageFile -LanguageCode $Language
        $InvokeRestartExplorer = $true

        & $script:completion_branch

        $script:ApplyCompletionTitleEl.Text | Should -Be (Get-Translation -Key 'ApplyCompletionTitleSuccess')
        $script:ApplyCompletionMessageEl.Text | Should -Be (Get-Translation -Key 'ApplyCompletionMessageReady')
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter {
            $Object -eq (Get-Translation -Key 'GuiChangesApplied')
        }
        Should -Invoke Get-RebootFeatureLabels -Times 1 -Exactly
    }
}
