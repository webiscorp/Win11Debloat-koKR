# Prints the header for the script
function Write-CliHeader {
    param (
        $title
    )

    $fullTitle = (Get-Translation -Key 'CliHeader' -FormatArgs @($title))

    if ($script:Params.ContainsKey("Sysprep")) {
        $fullTitle = (Get-Translation -Key 'CliHeaderSysprep' -FormatArgs @($fullTitle))
    }
    else {
        $fullTitle = (Get-Translation -Key 'CliHeaderUser' -FormatArgs @($fullTitle, (Get-UserName)))
    }

    Clear-Host
    Write-Host "-------------------------------------------------------------------------------------------"
    Write-Host $fullTitle
    Write-Host "-------------------------------------------------------------------------------------------"
}
