@echo off
setlocal

:: Read Korean notices as UTF-8 and restore the calling console code page before returning.
for /f "tokens=2 delims=:" %%a in ('chcp') do set "initial_code_page=%%a"
chcp 65001 >nul

:: Set Windows Terminal installation paths. (Default and Scoop installation)
set "wtDefaultPath=%LOCALAPPDATA%\Microsoft\WindowsApps\wt.exe"
set "wtScoopPath=%USERPROFILE%\scoop\apps\windows-terminal\current\wt.exe"
set "logDir=%LOCALAPPDATA%\Win11Debloat\Logs"
set "logFile=%logDir%\Win11Debloat-Run.log"

:: Ensure Logs folder exists
if not exist "%logDir%" mkdir "%logDir%"

:: Determine which terminal exists
if exist "%wtDefaultPath%" (
    set "wtPath=%wtDefaultPath%"
) else if exist "%wtScoopPath%" (
    set "wtPath=%wtScoopPath%"
) else (
    set "wtPath="
)

:: Interpolated into a PS single-quoted string below;
:: Apostrophes escaped via %:'=''% and -File arg uses [char]34 to avoid quote-parity bugs.
set "SCRIPT_PATH=%~dp0Win11Debloat.ps1"

if defined wtPath (
    call :Log Launching Win11Debloat.ps1 with Windows Terminal...
    PowerShell -NoProfile -ExecutionPolicy Bypass -Command "$p='%SCRIPT_PATH:'=''%'; $w='%wtPath:'=''%'; $q=[char]34; Start-Process -FilePath $w -ArgumentList ('PowerShell -NoProfile -ExecutionPolicy Bypass -File ' + $q + $p + $q) -Verb RunAs" >> "%logFile%" || call :Error "PowerShell을 실행하지 못했습니다."
) else (
    echo Windows Terminal을 찾을 수 없어 Windows PowerShell로 실행합니다. / Using Windows PowerShell...
    call :Log Windows Terminal not found. Using default PowerShell to launch Win11Debloat.ps1...
    PowerShell -NoProfile -ExecutionPolicy Bypass -Command "$p='%SCRIPT_PATH:'=''%'; $q=[char]34; Start-Process PowerShell -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File ' + $q + $p + $q) -Verb RunAs" >> "%logFile%" || call :Error "PowerShell을 실행하지 못했습니다."
)

echo.
echo 한국어판 사용 안내 및 지원 / Korean edition help and support:
echo https://github.com/webiscorp/Win11Debloat-koKR#support
chcp %initial_code_page% >nul
goto :EOF

:: Logging Function
:Log
echo(%* >> "%logFile%"
goto :EOF

:: Error Handler
:Error
echo(실행 오류 / ERROR: %*
call :Log ERROR: %*
echo 오류 기록 / Log: %logFile%
pause
goto :EOF
