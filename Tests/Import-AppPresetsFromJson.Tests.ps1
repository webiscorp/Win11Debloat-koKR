BeforeAll {
    $script:repo_root = Split-Path $PSScriptRoot -Parent
    . "$script:repo_root/Scripts/FileIO/Import-JsonFile.ps1"
    . "$script:repo_root/Scripts/FileIO/Import-LanguageFile.ps1"
    . "$script:repo_root/Scripts/FileIO/Import-AppPresetsFromJson.ps1"
    $script:LanguagesPath = Join-Path $script:repo_root 'Config/Languages'
}

Describe 'Stable app preset localization' {
    BeforeEach {
        $script:AppsListFilePath = Join-Path $TestDrive 'Apps.json'
        $script:Lang = Import-LanguageFile -LanguageCode 'ko-KR'
    }

    It 'adds stable IDs without changing shipped preset names or application IDs' {
        $script:AppsListFilePath = Join-Path $script:repo_root 'Config/Apps.json'
        $source = Get-Content -LiteralPath $script:AppsListFilePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $presets = @(Import-AppPresetsFromJson)
        $presets.PresetId | Should -Be @('xbox_gaming_apps', 'oem_software')
        for ($i = 0; $i -lt $presets.Count; $i++) {
            $presets[$i].Name | Should -Be $source.Presets[$i].Name
            $presets[$i].AppIds | Should -Be @($source.Presets[$i].AppIds)
        }
    }

    It 'uses the stable ID after a source name changes and preserves legacy custom presets' {
        '{"Presets":[{"PresetId":"xbox_gaming_apps","Name":"Renamed source","AppIds":["One.App"]},{"Name":"My apps","AppIds":["Two.App"]}]}' |
            Set-Content -LiteralPath $script:AppsListFilePath -Encoding UTF8
        $presets = @(Import-AppPresetsFromJson)
        (Get-AppPresetDisplayName -PresetId $presets[0].PresetId -FallbackName $presets[0].Name) |
            Should -Be (Get-Translation -Key 'AppPresetXboxGamingApps')
        $presets[0].Name | Should -Be 'Renamed source'
        $presets[0].AppIds | Should -Be @('One.App')
        (Get-AppPresetDisplayName -PresetId $presets[1].PresetId -FallbackName $presets[1].Name) |
            Should -Be 'My apps'
        $presets[1].AppIds | Should -Be @('Two.App')
    }

    It 'preserves unknown preset names and falls back safely when language resources are absent' {
        Get-AppPresetDisplayName -PresetId 'custom_preset' -FallbackName 'My apps' | Should -Be 'My apps'
        $script:Lang = $null
        Get-AppPresetDisplayName -PresetId 'xbox_gaming_apps' -FallbackName 'Xbox source name' | Should -Be 'Xbox source name'
    }

    It 'keeps native dialog file patterns unchanged across languages' {
        foreach ($language in @('en-US', 'ko-KR')) {
            $script:Lang = Import-LanguageFile -LanguageCode $language
            $json_filter = (Get-Translation -Key 'FileDialogJsonFilter') -split '\|'
            $json_filter.Count | Should -Be 4
            $json_filter[1] | Should -Be '*.json'
            $json_filter[3] | Should -Be '*.*'
            ((Get-Translation -Key 'FileDialogRegistryBackupFilter') -split '\|')[1] | Should -Be '*.json'
            ((Get-Translation -Key 'FileDialogStartMenuBackupFilter') -split '\|')[1] | Should -Be '*.bak'
        }
    }
}
