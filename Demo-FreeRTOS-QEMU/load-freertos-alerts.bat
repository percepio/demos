@echo off
setlocal EnableExtensions DisableDelayedExpansion

for %%I in ("%~dp0.") do set "PROJECT_ROOT=%%~fI"
set "DETECT_ROOT=C:\src\DetectRepo"
set "ALERT_DIR=%PROJECT_ROOT%\freertos-test"
set "QEMU_LOG=%PROJECT_ROOT%\qemu-gdb.log"
set "BUILD_DIR=%PROJECT_ROOT%\build\debug"
set "ELF_SOURCE=%BUILD_DIR%\Demo-FreeRTOS-QEMU.elf"
set "ELF_DEST=%ALERT_DIR%\image.elf"
set "SERVER_DIR=%DETECT_ROOT%\release-stage\percepio-server"
set "SERVER_BAT=%SERVER_DIR%\percepio-server.bat"
set "RECEIVER_DIR=%DETECT_ROOT%\release-stage\percepio-receiver"
set "RECEIVER_BAT=%RECEIVER_DIR%\percepio-receiver.bat"
set "CLIENT_DIR=%DETECT_ROOT%\percepio-client-windows"
set "CLIENT_BAT=%CLIENT_DIR%\percepio-client.bat"
set "DEVICE_NAME=FreeRTOSQEMU"

rem These variables are inherited by the Detect server and client processes.
set "DETECT_ALERT_DIR=%ALERT_DIR%"
set "DETECT_ELF_PATH=%ELF_DEST%"
set "DRY_RUN=0"

:parse_args
if "%~1"=="" goto args_done
if /I "%~1"=="--dry-run" (
    set "DRY_RUN=1"
) else (
    echo ERROR: Unexpected argument: %~1
    goto usage
)
shift
goto parse_args

:args_done
echo Checking configured paths...
set "PREFLIGHT_ERRORS=0"
call :check_required_directory PROJECT_ROOT "%PROJECT_ROOT%"
call :check_required_directory DETECT_ROOT "%DETECT_ROOT%"
call :check_required_directory BUILD_DIR "%BUILD_DIR%"
call :check_required_directory SERVER_DIR "%SERVER_DIR%"
call :check_required_directory RECEIVER_DIR "%RECEIVER_DIR%"
call :check_required_directory CLIENT_DIR "%CLIENT_DIR%"
call :check_required_file ELF_SOURCE "%ELF_SOURCE%"
call :check_required_file SERVER_BAT "%SERVER_BAT%"
call :check_required_file RECEIVER_BAT "%RECEIVER_BAT%"
call :check_required_file CLIENT_BAT "%CLIENT_BAT%"
call :check_required_file QEMU_LOG "%QEMU_LOG%"
call :check_directory_target ALERT_DIR "%ALERT_DIR%"
call :check_file_target ELF_DEST "%ELF_DEST%"
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

echo [1/7] Using the captured QEMU log "%QEMU_LOG%"...

findstr /L /C:"[[ DevAlert Data Begins ]]" "%QEMU_LOG%" >nul
if errorlevel 1 echo WARNING: The QEMU log contains no DFM DevAlert data.

echo [2/7] Stopping and resetting the Detect server...
pushd "%SERVER_DIR%"
call "%SERVER_BAT%" stop >nul 2>&1
(echo yes)|call "%SERVER_BAT%" cleanup >nul 2>&1
popd

echo [3/7] Stopping any running Detect client...
powershell.exe -NoProfile -Command "$stopped = 0; $processes = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue); foreach ($process in $processes) { if ((@('python.exe', 'pythonw.exe') -contains $process.Name) -and ($process.CommandLine -match 'percepio-client[.]py')) { Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue; $stopped++ } }; Write-Host ('      Stopped {0} client process(es).' -f $stopped)"

echo [4/7] Extracting alerts from the QEMU text log...
call "%RECEIVER_BAT%" txt --inputfile "%QEMU_LOG%" --folder "%ALERT_DIR%" --device_name "%DEVICE_NAME%" --eof exit
if errorlevel 1 goto receiver_failed

echo [5/7] Copying the FreeRTOS ELF as image.elf...
copy /B /Y "%ELF_SOURCE%" "%ELF_DEST%" >nul || goto copy_elf_failed

echo [6/7] Starting the Detect server...
pushd "%SERVER_DIR%"
call "%SERVER_BAT%" start
set "SERVER_RESULT=%ERRORLEVEL%"
popd
if not "%SERVER_RESULT%"=="0" goto server_failed

echo [7/7] Starting the Detect client...
start "Percepio Detect Client" /D "%CLIENT_DIR%" cmd.exe /c percepio-client.bat

echo.
echo Load complete.
echo QEMU log:  %QEMU_LOG%
echo Alerts:    %ALERT_DIR%
echo ELF:       %ELF_DEST%
exit /b 0

:dry_run
echo DRY RUN - no files, processes, containers, or Docker data will be changed.
echo [1/7] Would use the captured QEMU log "%QEMU_LOG%".
echo [2/7] Would call "%SERVER_BAT%" stop, then cleanup with confirmation "yes".
echo [3/7] Would stop python.exe/pythonw.exe processes running percepio-client.py.
echo [4/7] Would run the receiver with output folder "%ALERT_DIR%" and device name "%DEVICE_NAME%".
echo [5/7] Would copy "%ELF_SOURCE%" to "%ELF_DEST%".
echo [6/7] Would call "%SERVER_BAT%" start with DETECT_ALERT_DIR="%DETECT_ALERT_DIR%".
echo [7/7] Would start "%CLIENT_BAT%" with DETECT_ALERT_DIR and DETECT_ELF_PATH inherited.
exit /b 0

:usage
echo Usage: %~nx0 [--dry-run]
echo.
echo Loads this project's qemu-gdb.log and image ELF into freertos-test.
exit /b 2

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

:check_file_target
if "%~2"=="" (
    echo ERROR: %~1 is empty; expected a file path.
    set /a "PREFLIGHT_ERRORS+=1" >nul
    exit /b 0
)
if not exist "%~2\" exit /b 0
echo ERROR: %~1 points to a directory; expected a file path.
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

:copy_elf_failed
echo ERROR: Could not copy image.elf. The server and client remain stopped.
exit /b 1

:server_failed
echo ERROR: The Detect server could not be started. The client was not started.
exit /b 1
