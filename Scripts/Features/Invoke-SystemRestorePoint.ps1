<#
    .SYNOPSIS
    Creates a system restore point.

    .OUTPUTS
    System.Boolean. $true when a restore point is created; otherwise $false.
#>
function Invoke-SystemRestorePoint {
    $failed = $false
    $isSilent = ($script:Params -and $script:Params.ContainsKey('Silent')) -or $script:Silent
    # Translate in the caller: timeout workers run in isolated PowerShell runspaces.
    $restore_messages = @{
        enable_failed = Get-Translation -Key 'RuntimeRestoreEnableFailed'
        query_failed = Get-Translation -Key 'RuntimeRestoreExistingQueryFailed'
        created = Get-Translation -Key 'RuntimeRestorePointCreated'
        create_failed = Get-Translation -Key 'RuntimeRestorePointUnableToCreate'
        recent_exists = Get-Translation -Key 'RuntimeRestorePointRecentExists'
        description = Get-Translation -Key 'RuntimeRestorePointDescription'
    }

    try {
        $SysRestore = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "RPSessionInterval" -ErrorAction Stop
    }
    catch {
        Write-Host (Get-Translation -Key 'RuntimeRestoreStateQueryFailed' -FormatArgs @($_.Exception.Message)) -ForegroundColor Red
        $failed = $true
    }

    if (-not $failed -and $SysRestore.RPSessionInterval -eq 0) {
        # In GUI mode, skip the prompt and just try to enable it
        if ($script:GuiWindow -or $isSilent -or $( Read-Host -Prompt (Get-Translation -Key 'RuntimeRestoreEnablePrompt')) -eq 'y') {
            try {
                $enableResult = Invoke-NonBlocking -TimeoutSeconds 90 -ArgumentList @($restore_messages) -ScriptBlock {
                    param($restore_messages)
                    try {
                        Enable-ComputerRestore -Drive "$env:SystemDrive"
                        return $null
                    }
                    catch {
                        return ($restore_messages.enable_failed -f $_)
                    }
                }
            }
            catch {
                $enableResult = ($restore_messages.enable_failed -f $_)
            }

            if ($enableResult) {
                Write-Host $enableResult -ForegroundColor Red
                $failed = $true
            }
        }
        else {
            $failed = $true
        }
    }

    if (-not $failed) {
        try {
            $result = Invoke-NonBlocking -TimeoutSeconds 90 -ArgumentList @($restore_messages) -ScriptBlock {
                param($restore_messages)
                try {
                    $recentRestorePoints = Get-ComputerRestorePoint | Where-Object { (Get-Date) - [System.Management.ManagementDateTimeConverter]::ToDateTime($_.CreationTime) -le (New-TimeSpan -Hours 24) }
                }
                catch {
                    return [PSCustomObject]@{ Success = $false; Message = ($restore_messages.query_failed -f $_) }
                }

                if ($recentRestorePoints.Count -eq 0) {
                    try {
                        Checkpoint-Computer -Description $restore_messages.description -RestorePointType "MODIFY_SETTINGS"
                        return [PSCustomObject]@{ Success = $true; Message = $restore_messages.created }
                    }
                    catch {
                        return [PSCustomObject]@{ Success = $false; Message = ($restore_messages.create_failed -f $_) }
                    }
                }
                else {
                    return [PSCustomObject]@{ Success = $true; Message = $restore_messages.recent_exists }
                }
            }
        }
        catch {
            $result = [PSCustomObject]@{ Success = $false; Message = (Get-Translation -Key 'RuntimeRestorePointCreateException' -FormatArgs @($_)) }
        }

        if ($result -and $result.Success) {
            Write-Host $result.Message
        }
        elseif ($result) {
            Write-Host $result.Message -ForegroundColor Red
            $failed = $true
        }
        else {
            Write-Host (Get-Translation -Key 'RuntimeRestorePointCreateFailedNoDetail') -ForegroundColor Red
            $failed = $true
        }
    }

    # Ensure that the user is aware if creating a restore point failed, and give them the option to continue without a restore point or cancel the script
    if ($failed) {
        if ($script:GuiWindow) {
            $result = Show-MessageBox (Get-Translation -Key 'RestorePointFailedMessage') (Get-Translation -Key 'RestorePointFailedTitle') "YesNo" "Warning"

            if ($result -ne "Yes") {
                $script:CancelRequested = $true
                return $false
            }
        }
        elseif (-not $isSilent) {
            Write-Host (Get-Translation -Key 'RuntimeRestorePointContinuePrompt') -ForegroundColor Yellow
            if ($( Read-Host ) -ne 'y') {
                $script:CancelRequested = $true
                return $false
            }
        }

        Write-Host (Get-Translation -Key 'RuntimeRestorePointContinuingWithout') -ForegroundColor Yellow
        return $false
    }

    return $true
}
