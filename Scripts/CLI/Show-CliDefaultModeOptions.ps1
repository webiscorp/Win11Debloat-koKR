# Show CLI default mode options for removing apps, or set selection if RunDefaults or RunDefaultsLite parameter was passed
function Show-CliDefaultModeOptions {
    if ($RunDefaults) {
        $RemoveAppsInput = '1'
    }
    elseif ($RunDefaultsLite) {
        $RemoveAppsInput = '0'                
    }
    else {
        $RemoveAppsInput = Show-CliDefaultModeAppRemovalOptions

        if ($RemoveAppsInput -eq '2' -and ($script:SelectedApps.contains('Microsoft.XboxGameOverlay') -or $script:SelectedApps.contains('Microsoft.XboxGamingOverlay')) -and 
          $( Read-Host -Prompt (Get-Translation -Key 'CliDisableGameBarPrompt') ) -eq 'y') {
            $DisableGameBarIntegrationInput = $true;
        }
    }

    Write-CliHeader (Get-Translation -Key 'CliTitleDefault')

    try {
        # Select app removal options based on user input
        switch ($RemoveAppsInput) {
            '1' {
                Add-Parameter 'RemoveApps'
                Add-Parameter 'Apps' 'Default'
            }
            '2' {
                Add-Parameter 'RemoveApps'
                Add-Parameter 'Apps' ($script:SelectedApps -join ',')

                if ($DisableGameBarIntegrationInput) {
                    Add-Parameter 'DisableDVR'
                    Add-Parameter 'DisableGameBarIntegration'
                }
            }
        }

        Import-Settings -filePath $script:DefaultSettingsFilePath -expectedVersion "1.0"
    }
    catch {
        Write-Error (Get-Translation -Key 'CliDefaultSettingsLoadFailed' -FormatArgs @($_))
        Wait-ForKeyPress -ExitCode 1
    }

    Save-Settings

    if ($Silent) {
        # Skip change summary and confirmation prompt
        return
    }

    Write-PendingChanges
    Write-CliHeader (Get-Translation -Key 'CliTitleDefault')
}
