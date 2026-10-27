BeforeAll {
    $script:repo_root = Split-Path $PSScriptRoot -Parent
    . "$script:repo_root/Scripts/FileIO/Import-JsonFile.ps1"
    . "$script:repo_root/Scripts/FileIO/Import-LanguageFile.ps1"
    . "$script:repo_root/Scripts/GUI/Ui-Preferences.ps1"
    $script:LanguagesPath = Join-Path $script:repo_root 'Config/Languages'

    function get_catalog_values {
        param($catalog)
        foreach ($property in $catalog.PSObject.Properties) {
            if ($property.Value -is [PSCustomObject]) { get_catalog_values $property.Value }
            else { $property.Value }
        }
    }
}

Describe 'Korean resource and preference contracts (no Windows mutation)' {
    BeforeEach {
        $script:LanguagesPath = Join-Path $script:repo_root 'Config/Languages'
        $script:UiPreferencesFilePath = Join-Path $TestDrive 'Preferences.json'
    }

    It 'covers every English key and resolves Korean without fallback' {
        $coverage = Test-LanguageKeyCoverage -LanguageCode 'ko-KR'
        $coverage.ResolvedLanguageCode | Should -Be 'ko-KR'
        $coverage.MissingKeys | Should -BeNullOrEmpty
        $coverage.ExtraKeys | Should -BeNullOrEmpty
        $language_data = Import-LanguageFile -LanguageCode 'ko-KR'
        $language_data.LanguageCode | Should -Be 'ko-KR'
        $language_data.Fallback.LanguageCode | Should -Be 'en-US'
        $language_data.Chrome.MessageBoxOk | Should -Be ([string][char]0xD655 + [char]0xC778)
    }

    It 'formats every Korean catalog string with .NET composite formatting' {
        foreach ($name in Get-LanguageCatalogNames) {
            $catalog = Get-Content -LiteralPath (Join-Path $script:LanguagesPath "ko-KR/$name.json") -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($value in get_catalog_values $catalog) {
                $format_args = [object[]]@(0..31 | ForEach-Object { "sample_$_" })
                { [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, $value, $format_args) } | Should -Not -Throw
            }
        }
    }

    It 'auto-detects Korean UI culture without changing saved preferences' {
        Save-UiPreferences -Preferences @{ Theme = 'Auto'; Language = 'Auto' }
        $old_culture = [System.Threading.Thread]::CurrentThread.CurrentUICulture
        try {
            [System.Threading.Thread]::CurrentThread.CurrentUICulture = [System.Globalization.CultureInfo]::GetCultureInfo('ko-KR')
            Initialize-UiPreferences
            $script:Lang.LanguageCode | Should -Be 'ko-KR'
            $script:UiPreferences.Language | Should -Be 'Auto'
            (Get-UiPreferences).Language | Should -Be 'Auto'
        }
        finally { [System.Threading.Thread]::CurrentThread.CurrentUICulture = $old_culture }
    }

    It 'preserves saved English while an explicit Korean override is active' {
        Save-UiPreferences -Preferences @{ Theme = 'Dark'; Language = 'en-US' }
        Initialize-UiPreferences -Language 'ko-KR'
        $script:Lang.LanguageCode | Should -Be 'ko-KR'
        $script:UiPreferences.Theme | Should -Be 'Dark'
        (Get-UiPreferences).Language | Should -Be 'en-US'
        Initialize-UiPreferences
        $script:Lang.LanguageCode | Should -Be 'en-US'
    }

    It 'round trips Korean and English preferences without changing themes' {
        foreach ($language_code in @('ko-KR', 'en-US', 'ko-KR')) {
            Save-UiPreferences -Preferences @{ Theme = 'Light'; Language = $language_code }
            Initialize-UiPreferences
            $script:Lang.LanguageCode | Should -Be $language_code
            $script:UiPreferences.Theme | Should -Be 'Light'
        }
    }

    It 'loads UTF-8 Korean catalogs with and without BOM' {
        $fixture_path = Join-Path $TestDrive 'encodings'
        foreach ($has_bom in @($false, $true)) {
            foreach ($locale in @('en-US', 'ko-KR')) {
                $destination = Join-Path $fixture_path $locale
                [void][System.IO.Directory]::CreateDirectory($destination)
                foreach ($catalog_name in Get-LanguageCatalogNames) {
                    $source = Join-Path $script:LanguagesPath "$locale/$catalog_name.json"
                    $content = [System.IO.File]::ReadAllText($source)
                    [System.IO.File]::WriteAllText((Join-Path $destination "$catalog_name.json"), $content, [System.Text.UTF8Encoding]::new($has_bom))
                }
            }
            $loaded = Import-LanguageFile -LanguageCode 'ko-KR' -LanguagesPath $fixture_path
            $loaded.LanguageCode | Should -Be 'ko-KR'
            $loaded.Apps.'Microsoft.WindowsCalculator'.FriendlyName | Should -Be ([string][char]0xACC4 + [char]0xC0B0 + [char]0xAE30)
        }
    }

    It 'falls back to English when a Korean catalog is corrupt' {
        $fixture_path = Join-Path $TestDrive 'corrupt'
        [void][System.IO.Directory]::CreateDirectory($fixture_path)
        foreach ($locale in @('en-US', 'ko-KR')) {
            Copy-Item -LiteralPath (Join-Path $script:LanguagesPath $locale) -Destination $fixture_path -Recurse
        }
        [System.IO.File]::WriteAllText((Join-Path $fixture_path 'ko-KR/Apps.json'), '{invalid json')
        Mock Write-Error {}
        Mock Write-Warning {}
        $loaded = Import-LanguageFile -LanguageCode 'ko-KR' -LanguagesPath $fixture_path
        $loaded.LanguageCode | Should -Be 'en-US'
        $loaded.Chrome.MessageBoxOk | Should -Be 'OK'
    }

    It 'resolves every XAML translation marker using Korean resources' {
        $language_data = Import-LanguageFile -LanguageCode 'ko-KR'
        foreach ($path in Get-ChildItem -LiteralPath (Join-Path $script:repo_root 'Schemas') -Filter '*.xaml' -File) {
            $localized = ConvertTo-LocalizedXaml -Xaml (Get-Content -LiteralPath $path.FullName -Raw -Encoding UTF8) -Lang $language_data
            $localized | Should -Not -Match '%LANG:[A-Za-z0-9_]+%'
            { [xml]$localized } | Should -Not -Throw
        }
    }
}
