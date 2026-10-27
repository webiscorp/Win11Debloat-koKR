# Check if this machine supports S0 Modern Standby power state. Returns true if S0 Modern Standby is supported, false otherwise.
function Test-ModernStandbySupport {
    $count = 0

    try {
        switch -Regex (powercfg /a) {
            ':' {
                $count += 1
            }

            '(.*S0.{1,}\))' {
                if ($count -eq 1) {
                    return $true
                }
            }
        }
    }
    catch {
        Write-Host (Get-Translation -Key 'HelperModernStandbyCheckFailed') -ForegroundColor Red
        Write-Host ""
        Write-Host (Get-Translation -Key 'CliContinuePrompt')
        $null = [System.Console]::ReadKey()
        return $true
    }

    return $false
}
