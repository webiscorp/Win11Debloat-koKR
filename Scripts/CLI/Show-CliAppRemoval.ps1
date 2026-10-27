# Shows the CLI app removal menu and prompts the user to select which apps to remove.
function Show-CliAppRemoval {
    Write-CliHeader (Get-Translation -Key 'CliTitleAppRemoval')

    Write-Output (Get-Translation -Key 'CliOpeningAppSelection')

    $result = Show-AppSelectionWindow

    if ($result -eq $true) {
        Write-Output (Get-Translation -Key 'CliAppsSelected' -FormatArgs @($script:SelectedApps.Count))
        Add-Parameter 'RemoveApps'
        Add-Parameter 'Apps' ($script:SelectedApps -join ',')

        Save-Settings

        # Suppress prompt if Silent parameter was passed
        if (-not $Silent) {
            Write-Output ""
            Write-Output ""
            Write-Output (Get-Translation -Key 'CliConfirmRemove')
            Read-Host | Out-Null
            Write-CliHeader (Get-Translation -Key 'CliTitleAppRemoval')
        }
    }
    else {
        Write-Host (Get-Translation -Key 'CliRemovalCancelled') -ForegroundColor Red
        Write-Output ""
    }
}