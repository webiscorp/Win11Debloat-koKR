BeforeAll {
    function Invoke-NonBlocking { param($ScriptBlock, $ArgumentList, $TimeoutSeconds) }
    function Show-MessageBox { param($Message, $Title, $Button, $Icon) }
    function Enable-ComputerRestore { param($Drive) }
    function Get-ComputerRestorePoint {}
    function Checkpoint-Computer { param($Description, $RestorePointType) }
    . (Join-Path $PSScriptRoot '..\Scripts\FileIO\Import-JsonFile.ps1')
    . (Join-Path $PSScriptRoot '..\Scripts\FileIO\Import-LanguageFile.ps1')
    . (Join-Path $PSScriptRoot '..\Scripts\Features\Invoke-SystemRestorePoint.ps1')
    $script:LanguagesPath = Join-Path $PSScriptRoot '..\Config\Languages'
    $script:Lang = Import-LanguageFile -LanguageCode 'en-US'
}

Describe 'Invoke-SystemRestorePoint' {
    BeforeEach {
        $script:GuiWindow = $null
        $script:CancelRequested = $false
        $script:Silent = $false
        Mock Get-ItemProperty { [PSCustomObject]@{ RPSessionInterval = 1 } }
        Mock Invoke-NonBlocking { [PSCustomObject]@{ Success = $true; Message = 'System restore point created successfully' } }
        Mock Read-Host { 'y' }
        Mock Show-MessageBox { 'Yes' }
        Mock Write-Host {}
    }

    It 'creates a restore point when System Restore is already enabled' {
        Invoke-SystemRestorePoint

        Should -Invoke Invoke-NonBlocking -Times 1 -Exactly -ParameterFilter { $TimeoutSeconds -eq 90 }
        Should -Invoke Read-Host -Times 0 -Exactly
        $script:CancelRequested | Should -BeFalse
    }

    It 'returns false through the continuation flow when the System Restore state cannot be read' {
        Mock Get-ItemProperty { throw 'registry access denied' }
        Mock Read-Host { 'y' }

        Invoke-SystemRestorePoint | Should -BeFalse

        $script:CancelRequested | Should -BeFalse
        Should -Invoke Invoke-NonBlocking -Times 0 -Exactly
    }

    It 'returns false without prompting when the System Restore state cannot be read in silent mode' {
        $script:Silent = $true
        Mock Get-ItemProperty { throw 'registry access denied' }

        Invoke-SystemRestorePoint | Should -BeFalse

        $script:CancelRequested | Should -BeFalse
        Should -Invoke Read-Host -Times 0 -Exactly
    }

    It 'is loaded by the main entry point' {
        $entryPoint = Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\Win11Debloat.ps1') -Raw
        $expectedImport = [regex]::Escape('Scripts/Features/Invoke-SystemRestorePoint.ps1')

        $entryPoint | Should -Match $expectedImport
    }

    It 'enables disabled System Restore before creating the point in silent mode' {
        $script:Silent = $true
        Mock Get-ItemProperty { [PSCustomObject]@{ RPSessionInterval = 0 } }
        $script:nonBlockingCalls = 0
        Mock Invoke-NonBlocking {
            $script:nonBlockingCalls++
            if ($script:nonBlockingCalls -eq 1) { return $null }
            return [PSCustomObject]@{ Success = $true; Message = 'System restore point created successfully' }
        }

        Invoke-SystemRestorePoint

        Should -Invoke Invoke-NonBlocking -Times 2 -Exactly
        Should -Invoke Read-Host -Times 0 -Exactly
    }

    It 'enables System Restore only for the Windows system drive' {
        $script:Silent = $true
        $script:nonBlockingCalls = 0
        Mock Get-ItemProperty { [PSCustomObject]@{ RPSessionInterval = 0 } }
        Mock Invoke-NonBlocking {
            param($ScriptBlock, $ArgumentList)
            $script:nonBlockingCalls++
            if ($script:nonBlockingCalls -eq 1) {
                $script:enableRestoreBlock = $ScriptBlock
                $script:enable_restore_arguments = $ArgumentList
                return $null
            }
            return [PSCustomObject]@{ Success = $true; Message = 'System restore point created successfully' }
        }
        Mock Enable-ComputerRestore {}

        Invoke-SystemRestorePoint
        & $script:enableRestoreBlock @script:enable_restore_arguments

        Should -Invoke Enable-ComputerRestore -Times 1 -Exactly -ParameterFilter { $Drive -eq $env:SystemDrive }
    }

    It 'creates only a MODIFY_SETTINGS restore point with the project description' {
        $script:restorePointBlock = $null
        Mock Invoke-NonBlocking {
            param($ScriptBlock, $ArgumentList)
            $script:restorePointBlock = $ScriptBlock
            $script:restore_point_arguments = $ArgumentList
            return [PSCustomObject]@{ Success = $true; Message = 'System restore point created successfully' }
        }
        Mock Get-ComputerRestorePoint { @() }
        Mock Checkpoint-Computer {}

        Invoke-SystemRestorePoint
        & $script:restorePointBlock @script:restore_point_arguments

        Should -Invoke Checkpoint-Computer -Times 1 -Exactly -ParameterFilter {
            $Description -eq 'Restore point created by Win11Debloat' -and $RestorePointType -eq 'MODIFY_SETTINGS'
        }
    }

    It 'preserves Korean restore messages and description in an isolated runspace' {
        $script:Lang = Import-LanguageFile -LanguageCode 'ko-KR'
        Mock Invoke-NonBlocking {
            param($ScriptBlock, $ArgumentList)
            $script:korean_restore_worker = $ScriptBlock.ToString()
            $script:korean_restore_arguments = $ArgumentList
            [PSCustomObject]@{ Success = $true; Message = 'queued' }
        }
        $worker_powershell = [powershell]::Create()
        try {
            Invoke-SystemRestorePoint | Should -BeTrue
            $worker_setup = {
                param($worker, $worker_arguments)
                function Get-ComputerRestorePoint { @() }
                function Checkpoint-Computer {
                    param($Description, $RestorePointType)
                    $script:restore_description = $Description
                    $script:restore_point_type = $RestorePointType
                }
                $result = & ([scriptblock]::Create($worker)) @worker_arguments
                [PSCustomObject]@{
                    Result = $result
                    Description = $script:restore_description
                    RestorePointType = $script:restore_point_type
                }
            }
            $null = $worker_powershell.AddScript($worker_setup.ToString()).AddArgument($script:korean_restore_worker).AddArgument($script:korean_restore_arguments)
            $output = @($worker_powershell.Invoke())

            $worker_powershell.Streams.Error.Count | Should -Be 0
            $output[-1].Result.Success | Should -BeTrue
            $output[-1].Result.Message | Should -Be '시스템 복원 지점을 만들었습니다.'
            $output[-1].Description | Should -Be 'Win11Debloat에서 만든 복원 지점'
            $output[-1].RestorePointType | Should -Be 'MODIFY_SETTINGS'
        }
        finally {
            $worker_powershell.Dispose()
            $script:Lang = Import-LanguageFile -LanguageCode 'en-US'
        }
    }

    It 'cancels when an interactive user declines enabling disabled System Restore' {
        Mock Get-ItemProperty { [PSCustomObject]@{ RPSessionInterval = 0 } }
        Mock Read-Host { 'n' }

        Invoke-SystemRestorePoint

        Should -Invoke Invoke-NonBlocking -Times 0 -Exactly
        $script:CancelRequested | Should -BeTrue
    }

    It 'cancels when restore point creation fails and the CLI user declines continuation' {
        Mock Invoke-NonBlocking { [PSCustomObject]@{ Success = $false; Message = 'creation failed' } }
        Mock Read-Host { 'n' }

        Invoke-SystemRestorePoint

        $script:CancelRequested | Should -BeTrue
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'creation failed' }
    }

    It 'offers the CLI continuation choice when enabling System Restore fails' {
        Mock Get-ItemProperty { [PSCustomObject]@{ RPSessionInterval = 0 } }
        Mock Invoke-NonBlocking { throw 'enable failed' }
        Mock Read-Host { 'n' }

        Invoke-SystemRestorePoint

        $script:CancelRequested | Should -BeTrue
    }

    It 'continues after a GUI failure only when the dialog confirms it' {
        $script:GuiWindow = [PSCustomObject]@{}
        Mock Invoke-NonBlocking { $null }
        Mock Show-MessageBox { 'No' }

        Invoke-SystemRestorePoint

        $script:CancelRequested | Should -BeTrue
        Should -Invoke Show-MessageBox -Times 1 -Exactly
    }
}
