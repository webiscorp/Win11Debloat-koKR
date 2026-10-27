# Shows the CLI default mode app removal options. Loops until a valid option is selected.
function Show-CliDefaultModeAppRemovalOptions {
    Write-CliHeader (Get-Translation -Key 'CliTitleDefault')

    Write-Host (Get-Translation -Key 'CliDefaultAppsNotice') -ForegroundColor DarkGray
    Write-Host ""

    Do {
        Write-Host (Get-Translation -Key 'CliOptions') -ForegroundColor Yellow
        Write-Host (Get-Translation -Key 'CliRemoveNone') -ForegroundColor Yellow
        Write-Host (Get-Translation -Key 'CliRemoveDefault') -ForegroundColor Yellow
        Write-Host (Get-Translation -Key 'CliRemoveManual') -ForegroundColor Yellow
        $RemoveAppsInput = Read-Host (Get-Translation -Key 'CliRemovePrompt' -FormatArgs @((Get-FriendlyTargetUserName)))

        # Show app selection form if user entered option 3
        if ($RemoveAppsInput -eq '2') {
            $result = Show-AppSelectionWindow

            if ($result -ne $true) {
                # User cancelled or closed app selection, change RemoveAppsInput so the menu will be shown again
                Write-Host ""
                Write-Host (Get-Translation -Key 'CliSelectionCancelled') -ForegroundColor Red

                $RemoveAppsInput = 'c'
            }
            
            Write-Host ""
        }
        if ($RemoveAppsInput -notin @('n', '0', '1', '2', 'c')) {
            Write-Host (Get-Translation -Key 'CliInvalidSelection') -ForegroundColor Yellow
        }
    }
    while ($RemoveAppsInput -ne 'n' -and $RemoveAppsInput -ne '0' -and $RemoveAppsInput -ne '1' -and $RemoveAppsInput -ne '2')

    return $RemoveAppsInput
}