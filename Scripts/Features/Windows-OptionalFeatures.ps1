<#
    .SYNOPSIS
    Enables a Windows optional feature and pipes its output to the console.

    .OUTPUTS
    System.Boolean. $true when enabling succeeds or is previewed; otherwise $false.
#>
function Enable-WindowsFeature {
    param (
        [string]$FeatureName
    )

    if ($script:Params.ContainsKey("WhatIf")) {
        Write-Host (Get-Translation -Key 'RuntimeWindowsFeatureEnableWhatIf' -FormatArgs @($FeatureName)) -ForegroundColor Cyan
        return $true
    }

    try {
        $result = Invoke-NonBlocking -ScriptBlock {
            param($name)
            try {
                $output = Enable-WindowsOptionalFeature -Online -FeatureName $name -All -NoRestart -ErrorAction Stop
                return [PSCustomObject]@{
                    Success = $true
                    Output = if ($output) { ($output | Out-String).Trim() } else { $null }
                    Error = $null
                }
            }
            catch {
                return [PSCustomObject]@{
                    Success = $false
                    Output = $null
                    Error = $_.Exception.Message
                }
            }
        } -ArgumentList $FeatureName
    }
    catch {
        Write-Warning (Get-Translation -Key 'RuntimeWindowsFeatureEnableError' -FormatArgs @($FeatureName, $_.Exception.Message))
        return $false
    }

    if (-not $result -or -not $result.Success) {
        $details = if ($result -and $result.Error) { ": $($result.Error)" } else { '' }
        Write-Warning (Get-Translation -Key 'RuntimeWindowsFeatureEnableFailed' -FormatArgs @($FeatureName, $details))
        return $false
    }

    if ($result.Output) { Write-Host $result.Output }
    return $true
}

<#
    .SYNOPSIS
    Disables a Windows optional feature and pipes its output to the console.

    .OUTPUTS
    System.Boolean. $true when disabling succeeds or is previewed; otherwise $false.
#>
function Disable-WindowsFeature {
    param (
        [string]$FeatureName
    )

    if ($script:Params.ContainsKey("WhatIf")) {
        Write-Host (Get-Translation -Key 'RuntimeWindowsFeatureDisableWhatIf' -FormatArgs @($FeatureName)) -ForegroundColor Cyan
        return $true
    }

    try {
        $result = Invoke-NonBlocking -ScriptBlock {
            param($name)
            try {
                $output = Disable-WindowsOptionalFeature -Online -FeatureName $name -NoRestart -ErrorAction Stop
                return [PSCustomObject]@{
                    Success = $true
                    Output = if ($output) { ($output | Out-String).Trim() } else { $null }
                    Error = $null
                }
            }
            catch {
                return [PSCustomObject]@{
                    Success = $false
                    Output = $null
                    Error = $_.Exception.Message
                }
            }
        } -ArgumentList $FeatureName
    }
    catch {
        Write-Warning (Get-Translation -Key 'RuntimeWindowsFeatureDisableError' -FormatArgs @($FeatureName, $_.Exception.Message))
        return $false
    }

    if (-not $result -or -not $result.Success) {
        $details = if ($result -and $result.Error) { ": $($result.Error)" } else { '' }
        Write-Warning (Get-Translation -Key 'RuntimeWindowsFeatureDisableFailed' -FormatArgs @($FeatureName, $details))
        return $false
    }

    if ($result.Output) { Write-Host $result.Output }
    return $true
}

function Test-WindowsOptionalFeatureEnabled {
    param (
        [Parameter(Mandatory)]
        [string]$FeatureName
    )

    try {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName $FeatureName -ErrorAction Stop
    }
    catch {
        return $false
    }

    return ($feature.State -eq 'Enabled')
}
