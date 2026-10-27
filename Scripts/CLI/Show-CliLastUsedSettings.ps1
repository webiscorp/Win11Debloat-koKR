# Shows the CLI last used settings from LastUsedSettings.json file, displays pending changes and prompts the user to apply them.
function Show-CliLastUsedSettings {
    Write-CliHeader (Get-Translation -Key 'CliTitleCustom')

    try {
        Import-Settings -filePath $script:SavedSettingsFilePath -expectedVersion "1.0"
    }
    catch {
        Write-Error (Get-Translation -Key 'CliSavedSettingsLoadFailed' -FormatArgs @($_))
        Wait-ForKeyPress -ExitCode 1
    }

    if ($Silent) {
        # Skip change summary and confirmation prompt
        return
    }

    Write-PendingChanges
    Write-CliHeader (Get-Translation -Key 'CliTitleCustom')
}
