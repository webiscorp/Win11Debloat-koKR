<#
.SYNOPSIS
    Renders Korean WPF views without launching the application or applying changes.
.DESCRIPTION
    Creates off-screen test windows from XAML, with catalog-only app data and tweak
    definitions. Application launchers, installed-app detection, registry writes,
    uninstall operations, restore operations and Explorer restart are never invoked.
    96/144/192 DPI are bitmap raster densities, NOT actual Windows display-scale UAT.
#>
[CmdletBinding()]
param(
    [string]$output_path = (Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts/korean-ui')
)
$ErrorActionPreference = 'Stop'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'WPF smoke testing requires Windows.' }
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') { throw 'Run with powershell.exe -STA.' }
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase
$repo_root = Split-Path $PSScriptRoot -Parent
[void][System.IO.Directory]::CreateDirectory([System.IO.Path]::GetFullPath($output_path))
$output_path = [System.IO.Path]::GetFullPath($output_path)
foreach ($helper in @('FileIO/Import-JsonFile', 'FileIO/Import-LanguageFile', 'FileIO/Import-AppDetailsFromJson',
        'FileIO/Import-AppPresetsFromJson', 'GUI/Set-WindowThemeResources', 'GUI/MainWindow-Localization',
        'GUI/MainWindow-TweaksBuilder', 'GUI/MainWindow-AppSelection', 'GUI/Attach-ShiftClickBehavior',
        'Helpers/Windows-BuildHelpers', 'Threading/Invoke-DoEvents')) {
    . (Join-Path $PSScriptRoot "$helper.ps1")
}
$script:LanguagesPath = Join-Path $repo_root 'Config/Languages'
$script:FeaturesFilePath = Join-Path $repo_root 'Config/Features.json'
$script:AppsListFilePath = Join-Path $repo_root 'Config/Apps.json'
$script:SharedStylesSchema = Join-Path $repo_root 'Schemas/SharedStyles.xaml'
$script:Lang = Import-LanguageFile -LanguageCode 'ko-KR'
$script:Features = @{}
foreach ($feature in (Import-JsonFile -filePath $script:FeaturesFilePath).Features) { $script:Features[$feature.FeatureId] = $feature }
$script:ModernStandbySupported = $false
$script:JsonPresetCheckboxes = @()
$script:PendingDefaultMode = $false
$script:SortColumn = 'Name'
$script:SortAscending = $true
$script:AppSearchMatches = @()
$script:AppSearchMatchIndex = -1
$script:UpdatingLanguage = $true
$render_results = [System.Collections.Generic.List[object]]::new()
$failures = [System.Collections.Generic.List[string]]::new()

function get_visual_children {
    param([System.Windows.DependencyObject]$node)
    for ($index = 0; $index -lt [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($node); $index++) {
        $child = [System.Windows.Media.VisualTreeHelper]::GetChild($node, $index)
        $child
        get_visual_children -node $child
    }
}

function get_caption_metrics {
    param([System.Windows.FrameworkElement]$root)
    foreach ($node in get_visual_children -node $root) {
        if ($node -isnot [System.Windows.Controls.TextBlock] -or $node.ActualWidth -le 0 -or
            $node.Visibility -ne 'Visible' -or $node.Text -notmatch '[\uAC00-\uD7A3]') { continue }
        $ancestor = [System.Windows.Media.VisualTreeHelper]::GetParent($node)
        while ($ancestor -and $ancestor -isnot [System.Windows.Controls.Primitives.ButtonBase]) {
            $ancestor = [System.Windows.Media.VisualTreeHelper]::GetParent($ancestor)
        }
        if (-not $ancestor) { continue }
        $typeface = [System.Windows.Media.Typeface]::new($node.FontFamily, $node.FontStyle, $node.FontWeight, $node.FontStretch)
        $formatted = [System.Windows.Media.FormattedText]::new($node.Text,
            [System.Globalization.CultureInfo]::GetCultureInfo('ko-KR'), $node.FlowDirection,
            $typeface, $node.FontSize, [System.Windows.Media.Brushes]::Black,
            [System.Windows.Media.VisualTreeHelper]::GetDpi($node).PixelsPerDip)
        $unwrapped = $node.TextWrapping -eq [System.Windows.TextWrapping]::NoWrap
        $untrimmed = $node.TextTrimming -eq [System.Windows.TextTrimming]::None
        $potential_clipping = $unwrapped -and $untrimmed -and $formatted.WidthIncludingTrailingWhitespace -gt ($node.ActualWidth + 1.5)
        [PSCustomObject]@{ control = $ancestor.Name; control_type = $ancestor.GetType().Name; text = $node.Text;
            available_width_dip = [Math]::Round($node.ActualWidth, 2); text_width_dip = [Math]::Round($formatted.WidthIncludingTrailingWhitespace, 2);
            wrapping = [string]$node.TextWrapping; trimming = [string]$node.TextTrimming; potential_clipping = $potential_clipping }
    }
}

function save_view_render {
    param([System.Windows.Window]$window, [string]$view_name, [string]$theme, [int]$width, [int]$height)
    $window.Width = $width
    $window.Height = $height
    $window.UpdateLayout()
    if ($window.FindName('TweaksGrid')) { Update-TweaksResponsiveColumns -Window $window; $window.UpdateLayout() }
    $root = [System.Windows.FrameworkElement]$window.Content
    if ($root.ActualWidth -lt 1 -or $root.ActualHeight -lt 1) { throw "View has no measurable content: $view_name" }
    $metrics = @(get_caption_metrics -root $root)
    $clipped = @($metrics | Where-Object { $_.potential_clipping })
    foreach ($item in $clipped) { $failures.Add("Potential caption clipping in $view_name/$theme/$width`: $($item.control) [$($item.text)]") }
    foreach ($raster_dpi in @(96, 144, 192)) {
        $factor = $raster_dpi / 96.0
        $bitmap = [System.Windows.Media.Imaging.RenderTargetBitmap]::new(
            [int][Math]::Ceiling($root.ActualWidth * $factor), [int][Math]::Ceiling($root.ActualHeight * $factor),
            $raster_dpi, $raster_dpi, [System.Windows.Media.PixelFormats]::Pbgra32)
        $bitmap.Render($root)
        $encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
        $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
        $file_name = "${view_name}_${theme}_${width}dip_${raster_dpi}dpi.png"
        $stream = [System.IO.File]::Create((Join-Path $output_path $file_name))
        try { $encoder.Save($stream) } finally { $stream.Dispose() }
        $render_results.Add([PSCustomObject]@{ view = $view_name; theme = $theme; file = $file_name;
            width_dip = $root.ActualWidth; height_dip = $root.ActualHeight; raster_dpi = $raster_dpi;
            actual_host_dpi = [System.Windows.Media.VisualTreeHelper]::GetDpi($root).PixelsPerInchX;
            caption_metrics = $metrics; potential_clipping_count = $clipped.Count })
    }
}

function initialize_main_preview {
    param([System.Windows.Window]$window)
    $script:MainWindow = $window
    $script:GuiWindow = $null # No dispatcher pump from app row building is needed.
    New-DynamicTweakControls -Window $window -WinVersion 26100
    $script:PreloadedAppData = @(Import-AppDetailsFromJson) # No OnlyInstalled; no Appx/WinGet query.
    $appsPanel = $window.FindName('AppSelectionPanel')
    Add-AppsToMainWindow -Window $window -AppsPanel $appsPanel -OnlyInstalledAppsBox $window.FindName('OnlyInstalledAppsBox') `
        -LoadingAppsIndicator $window.FindName('LoadingAppsIndicator') -ImportConfigBtn $window.FindName('ImportConfigBtn')
    if ($appsPanel.Children.Count -eq 0) { throw 'Catalog-only app preview is empty.' }

    # Execute only the existing text-change handler. Do not dot-source or invoke Show-MainWindow.
    $tokens = $null; $parse_errors = $null
    $main_ast = [System.Management.Automation.Language.Parser]::ParseFile(
        (Join-Path $PSScriptRoot 'GUI/Show-MainWindow.ps1'), [ref]$tokens, [ref]$parse_errors)
    if ($parse_errors.Count) { throw 'Unable to parse app search handler.' }
    $handler_ast = @($main_ast.FindAll({ param($node)
        $node -is [System.Management.Automation.Language.InvokeMemberExpressionAst] -and
        $node.Member.Value -eq 'Add_TextChanged' -and $node.Expression.VariablePath.UserPath -eq 'appSearchBox'
    }, $true))
    if ($handler_ast.Count -ne 1) { throw 'App search handler contract changed; inspect before executing.' }
    $appSearchBox = $window.FindName('AppSearchBox')
    $appSearchPlaceholder = $window.FindName('AppSearchPlaceholder')
    $handler = [System.Windows.Controls.TextChangedEventHandler]$handler_ast[0].Arguments[0].ScriptBlock.GetScriptBlock()
    $appSearchBox.Add_TextChanged($handler)
    try {
        foreach ($query in @((Get-Translation -Key 'Microsoft.WindowsCalculator' -Field 'FriendlyName' -Section 'Apps'), 'Microsoft.WindowsCalculator')) {
            $appSearchBox.Text = $query
            $matches = @($script:AppSearchMatches | Where-Object { $_.AppIds -contains 'Microsoft.WindowsCalculator' })
            if ($matches.Count -ne 1) { throw "Korean/name-ID search failed: $query" }
        }
        $appSearchBox.Text = ''
    }
    finally { $appSearchBox.Remove_TextChanged($handler) }

    foreach ($language_code in @('en-US', 'ko-KR')) {
        $script:Lang = Import-LanguageFile -LanguageCode $language_code
        Update-WindowLanguageResources -Window $window
        Update-MainWindowTweakLanguage -Window $window
        Update-MainWindowAppLanguage -AppsPanel $appsPanel
        $actual_name = [System.Windows.Automation.AutomationProperties]::GetName($window.FindName('HomeDefaultModeBtn'))
        if ($actual_name -ne (Get-Translation -Key 'HomeDefaultModeBtn')) { throw 'Live language resource binding did not refresh.' }
    }
}

try {
    foreach ($theme in @('light', 'dark')) {
        foreach ($schema in Get-ChildItem -LiteralPath (Join-Path $repo_root 'Schemas') -Filter '*.xaml' -File) {
            if ($schema.Name -in @('SharedStyles.xaml', 'BubbleHint.xaml')) { continue }
            $window = $null
            try {
                $script:Lang = Import-LanguageFile -LanguageCode 'ko-KR'
                $xaml = Get-Content -LiteralPath $schema.FullName -Raw -Encoding UTF8
                if ($xaml -match 'x:(Class|Code)\s*=|<ObjectDataProvider') { throw 'Executable XAML is outside the preview scope.' }
                $is_main = $schema.Name -eq 'MainWindow.xaml'
                $localized = ConvertTo-LocalizedXaml -Xaml $xaml -DynamicResources:$is_main
                $window = [System.Windows.Markup.XamlReader]::Parse($localized)
                Set-WindowThemeResources -window $window -usesDarkMode ($theme -eq 'dark')
                if ($is_main) {
                    Update-WindowLanguageResources -Window $window
                    initialize_main_preview -window $window
                }
                if ($schema.Name -eq 'SettingsWindow.xaml') {
                    [void]$window.FindName('SettingsLanguageCombo').Items.Add([System.Globalization.CultureInfo]::GetCultureInfo('ko-KR').NativeName)
                    $window.FindName('SettingsLanguageCombo').SelectedIndex = 0
                }
                if ($schema.Name -eq 'MessageBox.xaml') {
                    $window.FindName('MessageText').Text = Get-Translation -Key 'RestorePointFailedMessage'
                }
                if ($schema.Name -eq 'ImportExportConfigWindow.xaml') {
                    $window.FindName('PromptText').Text = Get-Translation -Key 'ImportExportImportPrompt'
                }
                $window.WindowStartupLocation = 'Manual'
                $window.Left = -10000
                $window.Top = -10000
                $window.ShowActivated = $false
                $window.ShowInTaskbar = $false
                if ($is_main) { $window.Width = 1280; $window.Height = 800 }
                $window.Show()
                $window.UpdateLayout()
                if ($is_main) {
                    foreach ($layout_width in @(860, 1280)) {
                        for ($tab_index = 0; $tab_index -lt $window.FindName('MainTabControl').Items.Count; $tab_index++) {
                            $window.FindName('MainTabControl').SelectedIndex = $tab_index
                            save_view_render -window $window -view_name "MainWindow_tab$tab_index" -theme $theme -width $layout_width -height 800
                        }
                    }
                }
                else {
                    $view_width = [int][Math]::Ceiling($window.ActualWidth)
                    $view_height = [int][Math]::Ceiling($window.ActualHeight)
                    $window.SizeToContent = 'Manual'
                    save_view_render -window $window -view_name $schema.BaseName -theme $theme -width $view_width -height $view_height
                }
            }
            catch { $failures.Add("$($schema.Name)/$theme`: $($_.Exception.Message)") }
            finally { if ($window) { $window.Close() } }
        }
    }
}
finally {
    $report = [ordered]@{
        status = if ($failures.Count) { 'FAIL' } else { 'PASS' }
        host_os = [Environment]::OSVersion.VersionString
        runner_image = $env:ImageOS
        runner_image_version = $env:ImageVersion
        powershell = $PSVersionTable.PSVersion.ToString()
        renderer = 'WPF off-screen test windows; application entry point and apply actions not executed'
        feature_build_fixture = 26100
        raster_dpi = @(96, 144, 192)
        real_display_scale_test = 'NOT TESTED: raster DPI is not Windows display scaling'
        windows_10_11_uat = 'NOT TESTED: hosted Windows Server views are not client OS UAT'
        app_removal_registry_restore_reboot = 'NOT TESTED: intentionally excluded from rendering'
        input_method = 'NOT TESTED: text search uses programmatic Korean input, not a real IME'
        renders = @($render_results.ToArray())
        errors = @($failures.ToArray())
    }
    [System.IO.File]::WriteAllText((Join-Path $output_path 'ui-report.json'), ($report | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
}
if ($failures.Count) { throw ($failures -join "`n") }
Write-Output "Korean WPF view smoke PASS: $($render_results.Count) PNGs; real Windows 10/11 UAT remains NOT TESTED."
