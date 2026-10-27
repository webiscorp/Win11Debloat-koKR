<#
    .SYNOPSIS
    Restarts Windows Explorer to apply system changes.

    .DESCRIPTION
    Restarts the Explorer process to ensure all UI modifications take effect. Shows a warning if any of the applied features require a reboot to take full effect.
#>
function Invoke-RestartExplorer {
    if ($script:Params.ContainsKey("WhatIf")) {
        Write-Host (Get-Translation -Key 'RuntimeExplorerRestartWhatIf') -ForegroundColor Cyan
        return
    }

    Write-Host (Get-Translation -Key 'RuntimeExplorerRestartAttempt')

    if ($script:Params.ContainsKey('SkipExplorerRestart')) {
        Write-Host (Get-Translation -Key 'RuntimeExplorerRestartSkipped') -ForegroundColor Yellow
        return
    }

    $rebootFeatures = Get-RebootFeatureLabels
    foreach ($displayLabel in $rebootFeatures) {
        Write-Host (Get-Translation -Key 'RuntimeFeatureRequiresReboot' -FormatArgs @($displayLabel)) -ForegroundColor Yellow
    }

    # Only restart if the PowerShell process matches the OS architecture.
    # Restarting explorer from a 32bit PowerShell window will fail on a 64bit OS
    if ([Environment]::Is64BitProcess -eq [Environment]::Is64BitOperatingSystem) {
        Write-Host (Get-Translation -Key 'RuntimeExplorerRestartFlicker')
        Stop-Process -processName: Explorer -Force
    }
    else {
        Write-Host (Get-Translation -Key 'RuntimeExplorerRestartFailed') -ForegroundColor Yellow
    }
}
