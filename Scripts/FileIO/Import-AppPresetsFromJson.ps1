<#
    .SYNOPSIS
        Returns preset names, optional stable IDs and application IDs from Apps.json.
#>
function Import-AppPresetsFromJson {
    try {
        $jsonContent = Get-Content -Path $script:AppsListFilePath -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch {
        Write-Warning (Get-Translation -Key 'GuiAppsCatalogReadFailed' -FormatArgs @($_))
        return @()
    }

    if (-not $jsonContent.Presets) {
        return @()
    }

    return @($jsonContent.Presets | ForEach-Object {
        [PSCustomObject]@{
            Name     = $_.Name
            PresetId = [string]$_.PresetId
            AppIds   = @($_.AppIds)
        }
    })
}

<#
    .SYNOPSIS
        Localizes built-in preset names by stable ID, preserving custom and legacy names.
#>
function Get-AppPresetDisplayName {
    param([string]$PresetId, [string]$FallbackName)

    $translation_key = switch ($PresetId) {
        'xbox_gaming_apps' { 'AppPresetXboxGamingApps' }
        'oem_software' { 'AppPresetOemSoftware' }
        default { $null }
    }
    if ($translation_key) {
        $display_name = Get-Translation -Key $translation_key -Section 'Chrome'
        if ($display_name -and $display_name -ne $translation_key) { return $display_name }
    }
    return $FallbackName
}
