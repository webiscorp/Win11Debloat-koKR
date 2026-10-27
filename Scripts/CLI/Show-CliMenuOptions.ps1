# Shows the CLI menu options and prompts the user to select one. Loops until a valid option is selected.
function Show-CliMenuOptions {
    Do {
        $ModeSelectionMessage = (Get-Translation -Key 'CliSelectMode')

        Write-CliHeader (Get-Translation -Key 'CliTitleMenu')

        Write-Host (Get-Translation -Key 'CliMenuDefault')
        Write-Host (Get-Translation -Key 'CliMenuApps')

        # Only show this option if SavedSettings file exists
        if (Test-Path $script:SavedSettingsFilePath) {
            Write-Host (Get-Translation -Key 'CliMenuSaved')

            $ModeSelectionMessage = (Get-Translation -Key 'CliSelectModeWithSaved')
        }

        Write-Host ""
        Write-Host ""

        $Mode = Read-Host $ModeSelectionMessage

        if ($Mode -notin @('1', '2', '3')) {
            Write-Host (Get-Translation -Key 'CliInvalidSelection') -ForegroundColor Yellow
        }

        if (($Mode -eq '3') -and -not (Test-Path $script:SavedSettingsFilePath)) {
            $Mode = $null
        }
    }
    while ($Mode -ne '1' -and $Mode -ne '2' -and $Mode -ne '3')

    return $Mode
}