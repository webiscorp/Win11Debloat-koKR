BeforeAll {
    function Invoke-DoEvents {}
    . (Join-Path $PSScriptRoot '..\Scripts\Threading\Invoke-NonBlocking.ps1')
}

Describe 'Invoke-NonBlocking' {
    BeforeEach { $script:GuiWindow = $null }

    It 'runs directly in CLI mode without a timeout and preserves a scalar result' {
        Invoke-NonBlocking -ScriptBlock { param($Value) "result-$Value" } -ArgumentList 'one' | Should -Be 'result-one'
    }

    It 'runs directly in CLI mode without a timeout and preserves multiple results' {
        $result = @(Invoke-NonBlocking -ScriptBlock { 1; 2; 3 })
        $result | Should -Be @(1, 2, 3)
    }

    It 'stops a timed GUI operation and reports a timeout' {
        $script:GuiWindow = [PSCustomObject]@{}
        Mock Invoke-DoEvents {}

        { Invoke-NonBlocking -ScriptBlock { Start-Sleep -Seconds 3 } -TimeoutSeconds 1 } |
            Should -Throw 'Operation timed out after 1 seconds'
    }

    It 'uses a runspace and pumps UI events when a GUI window is present' {
        $script:GuiWindow = [PSCustomObject]@{}
        $gate = [System.Threading.ManualResetEventSlim]::new($false)
        Mock Invoke-DoEvents { $gate.Set() }

        try {
            $result = Invoke-NonBlocking -ScriptBlock {
                param($Event)
                if (-not $Event.Wait(5000)) { throw 'UI events were not pumped' }
                [System.Threading.Thread]::CurrentThread.ManagedThreadId
            } -ArgumentList @($gate) -TimeoutSeconds 5

            $result | Should -BeOfType ([int])
            $result | Should -Not -Be ([System.Threading.Thread]::CurrentThread.ManagedThreadId)
            Should -Invoke Invoke-DoEvents -Times 1
        }
        finally {
            $gate.Dispose()
        }
    }

    It 'surfaces non-terminating errors from a runspace' {
        $script:GuiWindow = [PSCustomObject]@{}
        Mock Invoke-DoEvents {}
        Mock Write-Error {}

        Invoke-NonBlocking -ScriptBlock { Write-Error 'runspace failure' }

        Should -Invoke Write-Error -Times 1 -Exactly -ParameterFilter { $ErrorRecord.Exception.Message -match 'runspace failure' }
    }

    It 'stops a timed CLI operation, reports a timeout, and remains usable afterward' {
        { Invoke-NonBlocking -ScriptBlock { Start-Sleep -Seconds 3 } -TimeoutSeconds 1 } |
            Should -Throw 'Operation timed out after 1 seconds'

        Invoke-NonBlocking -ScriptBlock { 'next operation' } -TimeoutSeconds 5 | Should -Be 'next operation'
    }
}

Describe 'Localized WinGet timeout reporting' {
    BeforeAll {
        . (Join-Path $PSScriptRoot '..\Scripts\FileIO\Import-JsonFile.ps1')
        . (Join-Path $PSScriptRoot '..\Scripts\FileIO\Import-LanguageFile.ps1')
        . (Join-Path $PSScriptRoot '..\Scripts\AppRemoval\Remove-SelectedApps.ps1')
        $script:LanguagesPath = Join-Path $PSScriptRoot '..\Config\Languages'
        # Keep the actual implementation before mocking its call site. Never run the uninstall worker.
        $script:timeout_implementation = (Get-Command Invoke-NonBlocking).ScriptBlock
    }

    BeforeEach {
        $script:Params = @{}
        $script:WingetInstalled = $true
        $script:WingetDeferredRemovals = @{}
        $script:GuiWindow = $null
        Mock Invoke-DoEvents {}
        Mock Write-Error {}
        Mock Set-RunOnceWingetTask { throw 'No removal should be scheduled in a timeout localization test.' }
        Mock Invoke-NonBlocking {
            param($ScriptBlock, $ArgumentList, $TimeoutSeconds)
            # Only replace the work: run the real timeout/runspace code with an inert delay.
            & $script:timeout_implementation -ScriptBlock { Start-Sleep -Seconds 3 } -TimeoutSeconds $TimeoutSeconds
        }
    }

    AfterEach { $script:GuiWindow = $null }

    It 'preserves the timeout sentinel and reports one <Language> error in <Mode> mode' -ForEach @(
        @{ Language = 'en-US'; Mode = 'CLI' }
        @{ Language = 'en-US'; Mode = 'GUI' }
        @{ Language = 'ko-KR'; Mode = 'CLI' }
        @{ Language = 'ko-KR'; Mode = 'GUI' }
    ) {
        $script:Lang = Import-LanguageFile -LanguageCode $Language
        if ($Mode -eq 'GUI') { $script:GuiWindow = [PSCustomObject]@{} }
        $script:expected_timeout_message = if ($Language -eq 'ko-KR') {
            'WinGet의 Example.TimeoutOnly 제거가 1초 안에 완료되지 않았습니다: Operation timed out after 1 seconds'
        }
        else {
            'WinGet uninstall for Example.TimeoutOnly did not complete within 1 seconds: Operation timed out after 1 seconds'
        }

        Remove-WinGetApp -app 'Example.TimeoutOnly' -TimeoutSeconds 1 | Should -BeFalse

        Should -Invoke Invoke-NonBlocking -Times 1 -Exactly -ParameterFilter { $TimeoutSeconds -eq 1 }
        Should -Invoke Write-Error -Times 1 -Exactly
        Should -Invoke Write-Error -Times 1 -Exactly -ParameterFilter { $Message -eq $script:expected_timeout_message }
        Should -Invoke Set-RunOnceWingetTask -Times 0 -Exactly
        $script:WingetDeferredRemovals.Count | Should -Be 0

        # The real runspace implementation must also remain usable after disposing the timed-out worker.
        & $script:timeout_implementation -ScriptBlock { 'next operation' } -TimeoutSeconds 5 | Should -Be 'next operation'
    }
}
