@echo off
setlocal EnableExtensions DisableDelayedExpansion

for %%I in ("%~dp0.") do set "PROJECT_ROOT=%%~fI"
set "DETECT_ROOT=C:\src\DetectRepo"
set "ALERT_DIR=%PROJECT_ROOT%\alert-files"
set "INPUT_LOG=%PROJECT_ROOT%\qemu_last_session.log"
set "ARTIFACT_ROOT=%PROJECT_ROOT%\dfm_test_artifacts"
set "SERVER_DIR=%DETECT_ROOT%\release-stage\percepio-server"
set "SERVER_BAT=%SERVER_DIR%\percepio-server.bat"
set "RECEIVER_DIR=%DETECT_ROOT%\release-stage\percepio-receiver"
set "RECEIVER_BAT=%RECEIVER_DIR%\percepio-receiver.bat"
set "CLIENT_DIR=%DETECT_ROOT%\percepio-client-windows"
set "CLIENT_BAT=%CLIENT_DIR%\percepio-client.bat"
set "DEVICE_NAME=ZephyrQEMU"

rem These variables are inherited by the Detect server and client processes.
set "DETECT_ALERT_DIR=%ALERT_DIR%"
rem The Client substitutes each alert's Revision, e.g. Build-M3-Os.
set "DETECT_ELF_PATH=../../demos/ZephyrDemo/dfm_test_artifacts/${revision}/zephyr.elf"
set "DRY_RUN=0"
set "CUSTOM_SERIAL_LOG=0"
set "CUSTOM_DEVICE_NAME=0"

:parse_args
if "%~1"=="" goto args_done
if /I "%~1"=="--dry-run" (
    set "DRY_RUN=1"
) else if /I "%~1"=="--serial-log" (
    if "%~2"=="" goto missing_argument
    for %%I in ("%~2") do set "INPUT_LOG=%%~fI"
    set "CUSTOM_SERIAL_LOG=1"
    shift
) else if /I "%~1"=="--device-name" (
    if "%~2"=="" goto missing_argument
    set "DEVICE_NAME=%~2"
    set "CUSTOM_DEVICE_NAME=1"
    shift
) else (
    echo ERROR: Unexpected argument: %~1
    goto usage
)
shift
goto parse_args

:args_done
if "%CUSTOM_SERIAL_LOG%"=="1" if not "%CUSTOM_DEVICE_NAME%"=="1" set "DEVICE_NAME=ZephyrBoard"

echo Checking configured paths...
set "PREFLIGHT_ERRORS=0"
call :check_required_directory PROJECT_ROOT "%PROJECT_ROOT%"
call :check_required_directory DETECT_ROOT "%DETECT_ROOT%"
call :check_required_directory ARTIFACT_ROOT "%ARTIFACT_ROOT%"
call :check_required_directory SERVER_DIR "%SERVER_DIR%"
call :check_required_directory RECEIVER_DIR "%RECEIVER_DIR%"
call :check_required_directory CLIENT_DIR "%CLIENT_DIR%"
call :check_required_file SERVER_BAT "%SERVER_BAT%"
call :check_required_file RECEIVER_BAT "%RECEIVER_BAT%"
call :check_required_file CLIENT_BAT "%CLIENT_BAT%"
call :check_required_file INPUT_LOG "%INPUT_LOG%"
call :check_directory_target ALERT_DIR "%ALERT_DIR%"
if not "%PREFLIGHT_ERRORS%"=="0" (
    echo.
    echo ERROR: Path validation found %PREFLIGHT_ERRORS% problem^(s^). Nothing was changed.
    exit /b 1
)
echo Path preflight passed.
echo.

if "%DRY_RUN%"=="1" goto dry_run

call :ensure_directory ALERT_DIR "%ALERT_DIR%"
if errorlevel 1 exit /b 1

echo [1/6] Using the captured target log "%INPUT_LOG%"...

findstr /L /C:"[[ DevAlert Data Begins ]]" "%INPUT_LOG%" >nul
if errorlevel 1 echo WARNING: The target log contains no DFM DevAlert data.

echo [2/6] Stopping and resetting the Detect server...
pushd "%SERVER_DIR%"
call "%SERVER_BAT%" stop >nul 2>&1
(echo yes)|call "%SERVER_BAT%" cleanup >nul 2>&1
popd

echo [3/6] Stopping any running Detect client...
powershell.exe -NoProfile -Command "$stopped = 0; $processes = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue); foreach ($process in $processes) { if ((@('python.exe', 'pythonw.exe') -contains $process.Name) -and ($process.CommandLine -match 'percepio-client[.]py')) { Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue; $stopped++ } }; Write-Host ('      Stopped {0} client process(es).' -f $stopped)"

echo [4/6] Extracting alerts from the target text log...
call "%RECEIVER_BAT%" txt --inputfile "%INPUT_LOG%" --folder "%ALERT_DIR%" --device_name "%DEVICE_NAME%" --eof exit
if errorlevel 1 goto receiver_failed

echo [5/6] Starting the Detect server...
pushd "%SERVER_DIR%"
call "%SERVER_BAT%" start
set "SERVER_RESULT=%ERRORLEVEL%"
popd
if not "%SERVER_RESULT%"=="0" goto server_failed

echo [6/6] Starting the Detect client...
start "Percepio Detect Client" /D "%CLIENT_DIR%" cmd.exe /c percepio-client.bat

echo.
echo Load complete.
echo Input log: %INPUT_LOG%
echo Alerts:    %ALERT_DIR%
echo ELF path:  %DETECT_ELF_PATH%
exit /b 0

:dry_run
echo DRY RUN - no files, processes, containers, or Docker data will be changed.
echo [1/6] Would use the captured target log "%INPUT_LOG%".
echo [2/6] Would call "%SERVER_BAT%" stop, then cleanup with confirmation "yes".
echo [3/6] Would stop python.exe/pythonw.exe processes running percepio-client.py.
echo [4/6] Would run the receiver with output folder "%ALERT_DIR%" and device name "%DEVICE_NAME%".
echo [5/6] Would call "%SERVER_BAT%" start with DETECT_ALERT_DIR="%DETECT_ALERT_DIR%".
echo [6/6] Would start "%CLIENT_BAT%" with DETECT_ELF_PATH="%DETECT_ELF_PATH%".
exit /b 0

:usage
echo Usage: %~nx0 [--serial-log FILE] [--device-name NAME] [--dry-run]
echo.
echo With no input options, loads qemu_last_session.log.
echo Each alert's Revision selects dfm_test_artifacts\Revision\zephyr.elf.
exit /b 2

:missing_argument
echo ERROR: Missing value after %~1.
goto usage

:check_required_directory
if "%~2"=="" (
    echo ERROR: %~1 is empty; expected an existing directory.
    set /a "PREFLIGHT_ERRORS+=1" >nul
    exit /b 0
)
if exist "%~2\" exit /b 0
if exist "%~2" (
    echo ERROR: %~1 points to a file; expected a directory.
) else (
    echo ERROR: Directory configured by %~1 was not found.
)
echo        Resolved path: "%~2"
set /a "PREFLIGHT_ERRORS+=1" >nul
exit /b 0

:check_required_file
if "%~2"=="" (
    echo ERROR: %~1 is empty; expected an existing file.
    set /a "PREFLIGHT_ERRORS+=1" >nul
    exit /b 0
)
if exist "%~2\" (
    echo ERROR: %~1 points to a directory; expected a file.
    echo        Resolved path: "%~2"
    set /a "PREFLIGHT_ERRORS+=1" >nul
    exit /b 0
)
if exist "%~2" exit /b 0
echo ERROR: File configured by %~1 was not found.
echo        Resolved path: "%~2"
set /a "PREFLIGHT_ERRORS+=1" >nul
exit /b 0

:check_directory_target
if "%~2"=="" (
    echo ERROR: %~1 is empty; expected a directory path.
    set /a "PREFLIGHT_ERRORS+=1" >nul
    exit /b 0
)
if exist "%~2\" exit /b 0
if not exist "%~2" exit /b 0
echo ERROR: %~1 points to a file; expected a directory path.
echo        Resolved path: "%~2"
set /a "PREFLIGHT_ERRORS+=1" >nul
exit /b 0

:ensure_directory
if exist "%~2\" exit /b 0
mkdir "%~2" >nul 2>&1
if exist "%~2\" exit /b 0
echo ERROR: Could not create the directory configured by %~1.
echo        Resolved path: "%~2"
exit /b 1

:receiver_failed
echo ERROR: The Percepio receiver failed. The server and client remain stopped.
exit /b 1

:server_failed
echo ERROR: The Detect server could not be started. The client was not started.
exit /b 1
