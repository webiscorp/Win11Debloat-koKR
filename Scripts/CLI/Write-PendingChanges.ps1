<#
    .SYNOPSIS
        Prints a summary of all pending changes to the console for the user to review.

    .DESCRIPTION
        Iterates over every non-control parameter in $script:Params and emits a
        human-readable line for each change that will be applied. For the
        'RemoveApps' parameter the list of targeted app names is displayed
        inline. Feature labels are resolved from Features.json when available;
        otherwise the raw parameter name is used as a fallback.

        After printing the summary the function pauses until the user presses
        Enter, giving them an opportunity to review and cancel via Ctrl+C.
#>
function Write-PendingChanges {
    Write-Output (Get-Translation -Key 'CliPendingChanges')

    if ($script:Params['CreateRestorePoint']) {
        Write-Output "- $(Get-Translation -Key 'CreateRestorePoint' -Field 'Label' -Section 'Features')"
    }
    foreach ($parameterName in $script:Params.Keys) {
        if ($script:ControlParams -contains $parameterName) {
            continue
        }

        # Print parameter description
        switch ($parameterName) {
            'Apps' {
                continue
            }
            'CreateRestorePoint' {
                continue
            }
            'RemoveApps' {
                $appsList = Generate-AppsList

                if ($appsList.Count -eq 0) {
                    Write-Host (Get-Translation -Key 'CliNoAppsSelected') -ForegroundColor Yellow
                    Write-Output ""
                    continue
                }

                Write-Output (Get-Translation -Key 'CliRemoveAppsSummary' -FormatArgs @($appsList.Count))
                Write-Host $appsList -ForegroundColor DarkGray
                continue
            }
            default {
                $message = Get-Translation -Key $parameterName -Field 'Label' -Section 'Features'
                Write-Output "- $message"
                continue
            }
        }
    }

    Write-Output ""
    Write-Output ""
    Write-Output (Get-Translation -Key 'CliConfirmChanges')
    Read-Host | Out-Null
}
