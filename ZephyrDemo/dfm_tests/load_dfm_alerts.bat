@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Load every saved DFM test image log into a clean Detect installation.
rem This script intentionally has no command-line options.

for %%I in ("%~dp0..") do set "ZEPHYR_ROOT=%%~fI"
set "ARTIFACT_ROOT=%ZEPHYR_ROOT%\dfm_test_artifacts"
for %%I in ("%ZEPHYR_ROOT%\..\..\DetectRepo") do set "DETECT_ROOT=%%~fI"
set "ALERT_DIR=%DETECT_ROOT%\zephyr-test\alert-files"
set "SERVER_DIR=%DETECT_ROOT%\release-stage\percepio-server"
set "SERVER_BAT=%SERVER_DIR%\percepio-server.bat"
set "RECEIVER_DIR=%DETECT_ROOT%\release-stage\percepio-receiver"
set "RECEIVER_BAT=%RECEIVER_DIR%\percepio-receiver.bat"
set "CLIENT_DIR=%DETECT_ROOT%\percepio-client-windows"
set "CLIENT_BAT=%CLIENT_DIR%\percepio-client.bat"
set "SERVER_CONTAINERS=detect-alert-sender detect-frontend detect-backend detect-database"
set "DATABASE_VOLUME=percepio_database"

if not "%~1"=="" (
    echo ERROR: This script takes no arguments.
    echo Usage: %~nx0
    exit /b 2
)

echo Checking configured paths and saved QEMU logs...
set "PREFLIGHT_ERRORS=0"
call :check_required_directory DETECT_ROOT "%DETECT_ROOT%"
call :check_required_directory ARTIFACT_ROOT "%ARTIFACT_ROOT%"
call :check_required_directory SERVER_DIR "%SERVER_DIR%"
call :check_required_directory RECEIVER_DIR "%RECEIVER_DIR%"
call :check_required_directory CLIENT_DIR "%CLIENT_DIR%"
call :check_required_file SERVER_BAT "%SERVER_BAT%"
call :check_required_file RECEIVER_BAT "%RECEIVER_BAT%"
call :check_required_file CLIENT_BAT "%CLIENT_BAT%"
call :check_directory_target ALERT_DIR "%ALERT_DIR%"

set /a "LOG_COUNT=0" >nul
if exist "%ARTIFACT_ROOT%\" (
    for /f "delims=" %%D in ('dir /b /ad "%ARTIFACT_ROOT%\Build-*" 2^>nul ^| sort') do (
        if exist "%ARTIFACT_ROOT%\%%D\qemu.log" set /a "LOG_COUNT+=1" >nul
    )
)
if "!LOG_COUNT!"=="0" (
    echo ERROR: No Build-*\qemu.log files were found below ARTIFACT_ROOT.
    echo        Resolved path: "%ARTIFACT_ROOT%"
    set /a "PREFLIGHT_ERRORS+=1" >nul
)

if not "!PREFLIGHT_ERRORS!"=="0" (
    echo.
    echo ERROR: Path validation found !PREFLIGHT_ERRORS! problem^(s^). Nothing was changed.
    exit /b 1
)

call :ensure_directory ALERT_DIR "%ALERT_DIR%"
if errorlevel 1 exit /b 1

echo Path preflight passed. Found !LOG_COUNT! QEMU log^(s^).
docker info >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is unavailable. Start Docker Desktop and try again.
    exit /b 1
)
echo.
echo [1/6] Cleaning the Detect server and its persistent database...
pushd "%SERVER_DIR%"
rem Redirect confirmation from a file. A pipe into CALL can lose stdin when
rem cmd.exe starts the nested batch file, causing cleanup to be aborted.
set "CONFIRM_FILE=%TEMP%\load_dfm_alerts_cleanup_!RANDOM!_!RANDOM!.txt"
>"!CONFIRM_FILE!" echo yes
call "%SERVER_BAT%" cleanup < "!CONFIRM_FILE!"
set "CLEANUP_RESULT=!ERRORLEVEL!"
del /f /q "!CONFIRM_FILE!" >nul 2>&1
popd
if not "!CLEANUP_RESULT!"=="0" (
    echo ERROR: percepio-server.bat cleanup failed with exit code !CLEANUP_RESULT!.
    exit /b 1
)
call :verify_server_removed
if errorlevel 1 exit /b 1

echo [2/6] Stopping the Detect client once...
powershell.exe -NoProfile -Command "$stopped = 0; $processes = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue); foreach ($process in $processes) { if ((@('python.exe', 'pythonw.exe') -contains $process.Name) -and ($process.CommandLine -match 'percepio-client[.]py')) { Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue; $stopped++ } }; Write-Host ('      Stopped {0} client process(es).' -f $stopped)"

echo [3/6] Deleting old alert files from "%ALERT_DIR%"...
del /f /s /q "%ALERT_DIR%\*" >nul 2>&1
set "DELETE_FAILED=0"
for /r "%ALERT_DIR%" %%F in (*) do (
    echo ERROR: Could not delete "%%F".
    set "DELETE_FAILED=1"
)
if "!DELETE_FAILED!"=="1" goto alert_delete_failed

echo [4/6] Loading saved QEMU logs through the Receiver...
set /a "LOG_INDEX=0" >nul
set /a "RECEIVER_FAILURES=0" >nul
for /f "delims=" %%D in ('dir /b /ad "%ARTIFACT_ROOT%\Build-*" 2^>nul ^| sort') do (
    set "QEMU_LOG=%ARTIFACT_ROOT%\%%D\qemu.log"
    if exist "!QEMU_LOG!" (
        set /a "LOG_INDEX+=1" >nul
        echo.
        echo [!LOG_INDEX!/!LOG_COUNT!] "!QEMU_LOG!"
        findstr /L /C:"[[ DevAlert Data Begins ]]" "!QEMU_LOG!" >nul
        if errorlevel 1 echo WARNING: This log contains no DFM DevAlert data.

        call "%RECEIVER_BAT%" txt --inputfile "!QEMU_LOG!" --folder "%ALERT_DIR%" --device_name ZephyrQEMU --eof exit
        if errorlevel 1 (
            echo ERROR: The Receiver failed for "!QEMU_LOG!".
            set /a "RECEIVER_FAILURES+=1" >nul
        ) else (
            echo PASS: Receiver completed for "!QEMU_LOG!".
        )
    )
)

echo.
echo [5/6] Starting the Detect server...
call :start_server
if errorlevel 1 exit /b 1

echo [6/6] Starting the Detect client once...
call :start_client
if errorlevel 1 exit /b 1

if not "!RECEIVER_FAILURES!"=="0" (
    echo.
    echo ERROR: !RECEIVER_FAILURES! of !LOG_COUNT! Receiver invocation^(s^) failed.
    echo Detect was restarted, but the loaded alert set is incomplete.
    exit /b 1
)

echo.
echo PASS: Loaded !LOG_COUNT! QEMU log^(s^) and restarted Detect.
echo Alerts: "%ALERT_DIR%"
exit /b 0

:alert_delete_failed
echo ERROR: The alert directory could not be emptied. No logs were loaded.
echo Attempting to restart the Detect server and client before exiting...
call :start_server
if not errorlevel 1 call :start_client
exit /b 1

:start_server
pushd "%SERVER_DIR%"
call "%SERVER_BAT%" start
set "SERVER_RESULT=!ERRORLEVEL!"
popd
if not "!SERVER_RESULT!"=="0" (
    echo ERROR: percepio-server.bat start failed with exit code !SERVER_RESULT!.
    exit /b 1
)
call :verify_server_running
if errorlevel 1 exit /b 1
exit /b 0

:verify_server_removed
set "REMOVE_ERRORS=0"
for %%C in (%SERVER_CONTAINERS%) do (
    docker container inspect "%%C" >nul 2>&1
    if not errorlevel 1 (
        echo ERROR: Detect container "%%C" remains after cleanup.
        set "REMOVE_ERRORS=1"
    )
)
docker volume inspect "%DATABASE_VOLUME%" >nul 2>&1
if not errorlevel 1 (
    echo ERROR: Detect database volume "%DATABASE_VOLUME%" remains after cleanup.
    set "REMOVE_ERRORS=1"
)
if "!REMOVE_ERRORS!"=="1" (
    echo ERROR: Detect cleanup was incomplete. Alerts were not reloaded.
    exit /b 1
)
echo PASS: Detect containers and database volume were removed.
exit /b 0

:verify_server_running
set "START_ERRORS=0"
for %%C in (%SERVER_CONTAINERS%) do (
    set "CONTAINER_RUNNING="
    for /f "usebackq delims=" %%R in (`docker container inspect --format "{{.State.Running}}" "%%C" 2^>nul`) do set "CONTAINER_RUNNING=%%R"
    if /i not "!CONTAINER_RUNNING!"=="true" (
        echo ERROR: Detect container "%%C" is not running after start.
        set "START_ERRORS=1"
    )
)
if "!START_ERRORS!"=="1" exit /b 1
echo PASS: All Detect server containers are running.
exit /b 0

:start_client
start "Percepio Detect Client" /D "%CLIENT_DIR%" cmd.exe /c percepio-client.bat
if errorlevel 1 (
    echo ERROR: The Detect client could not be started from "%CLIENT_DIR%".
    exit /b 1
)
exit /b 0

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
