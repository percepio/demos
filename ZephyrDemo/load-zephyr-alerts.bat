@echo off
setlocal EnableExtensions EnableDelayedExpansion

for %%I in ("%~dp0.") do set "PROJECT_ROOT=%%~fI"
set "DETECT_ROOT=C:\src\DetectRepo"
set "ALERT_DIR=%PROJECT_ROOT%\alert-files"
set "ARTIFACT_ROOT=%PROJECT_ROOT%\dfm_test_artifacts"
set "QEMU_FALLBACK_LOG=%PROJECT_ROOT%\qemu_last_session.log"
set "SERVER_DIR=%DETECT_ROOT%\release-stage\percepio-server"
set "SERVER_BAT=%SERVER_DIR%\percepio-server.bat"
set "RECEIVER_DIR=%DETECT_ROOT%\release-stage\percepio-receiver"
set "RECEIVER_BAT=%RECEIVER_DIR%\percepio-receiver.bat"
set "CLIENT_DIR=%DETECT_ROOT%\percepio-client-windows"
set "CLIENT_BAT=%CLIENT_DIR%\percepio-client.bat"
set "SERVER_CONTAINERS=detect-alert-sender detect-frontend detect-backend detect-database"
set "DATABASE_VOLUME=percepio_database"
set "SUITE_ELF_PATH=../../demos/ZephyrDemo/dfm_test_artifacts/${revision}/zephyr.elf"
set "MANUAL_ELF_PATH=../../demos/ZephyrDemo/build/zephyr/zephyr.elf"
set "MANUAL_ELF_FILE=%PROJECT_ROOT%\build\zephyr\zephyr.elf"

rem These variables are inherited by the Detect server and client processes.
set "DETECT_ALERT_DIR=%ALERT_DIR%"
rem Suite alerts select an ELF through Revision. Manual F5 runs switch this to
rem the current build\zephyr\zephyr.elf instead, without touching suite artifacts.
set "DETECT_ELF_PATH=%SUITE_ELF_PATH%"

set "DRY_RUN=0"
set "RECEIVER_ONLY=0"
set "INPUT_MODE=AUTO"
set "INPUT_LOG="
set "LOG_FILE_NAME="
set "LOG_KIND="
set "LOG_COUNT=0"
set "CUSTOM_DEVICE_NAME=0"
set "DEVICE_NAME=ZephyrQEMU"

:parse_args
if "%~1"=="" goto args_done
if /I "%~1"=="--dry-run" (
    set "DRY_RUN=1"
) else if /I "%~1"=="--receiver-only" (
    set "RECEIVER_ONLY=1"
) else if /I "%~1"=="--serial-log" (
    if "%~2"=="" goto missing_argument
    for %%I in ("%~2") do set "INPUT_LOG=%%~fI"
    set "INPUT_MODE=SINGLE"
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
echo Checking configured paths and current DFM test artifacts...
set "PREFLIGHT_ERRORS=0"
call :check_required_directory PROJECT_ROOT "%PROJECT_ROOT%"
call :check_required_directory DETECT_ROOT "%DETECT_ROOT%"
call :check_directory_target ARTIFACT_ROOT "%ARTIFACT_ROOT%"
call :check_required_directory RECEIVER_DIR "%RECEIVER_DIR%"
call :check_required_file RECEIVER_BAT "%RECEIVER_BAT%"
call :check_directory_target ALERT_DIR "%ALERT_DIR%"
if "%RECEIVER_ONLY%"=="0" (
    call :check_required_directory SERVER_DIR "%SERVER_DIR%"
    call :check_required_directory CLIENT_DIR "%CLIENT_DIR%"
    call :check_required_file SERVER_BAT "%SERVER_BAT%"
    call :check_required_file CLIENT_BAT "%CLIENT_BAT%"
)

if "%INPUT_MODE%"=="SINGLE" (
    set "LOG_KIND=explicit hardware serial"
    set "LOG_COUNT=1"
    if "%CUSTOM_DEVICE_NAME%"=="0" set "DEVICE_NAME=ZephyrBoard"
    call :check_required_directory ARTIFACT_ROOT "%ARTIFACT_ROOT%"
    call :check_required_file INPUT_LOG "!INPUT_LOG!"
) else (
    call :discover_artifact_logs
)

if not "!PREFLIGHT_ERRORS!"=="0" (
    echo.
    echo ERROR: Path and input validation found !PREFLIGHT_ERRORS! problem^(s^). Nothing was changed.
    exit /b 1
)

echo Path preflight passed. Selected !LOG_COUNT! !LOG_KIND! log^(s^).
call :print_selected_logs
echo.

if "%DRY_RUN%"=="1" goto dry_run

call :ensure_directory ALERT_DIR "%ALERT_DIR%"
if errorlevel 1 exit /b 1

if "%RECEIVER_ONLY%"=="1" goto receiver_only_prepare

docker info >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is unavailable. Start Docker Desktop and try again.
    exit /b 1
)

echo [1/6] Cleaning the Detect server and its persistent database...
pushd "%SERVER_DIR%"
rem Redirect confirmation from a file. A pipe into CALL can lose stdin when
rem cmd.exe starts the nested batch file, causing cleanup to be aborted.
set "CONFIRM_FILE=%TEMP%\load_zephyr_alerts_cleanup_!RANDOM!_!RANDOM!.txt"
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

echo [2/6] Stopping any running Detect client...
powershell.exe -NoProfile -Command "$stopped = 0; $processes = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue); foreach ($process in $processes) { if ((@('python.exe', 'pythonw.exe') -contains $process.Name) -and ($process.CommandLine -match 'percepio-client[.]py')) { Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue; $stopped++ } }; Write-Host ('      Stopped {0} client process(es).' -f $stopped)"

:delete_alerts
if "%RECEIVER_ONLY%"=="1" (
    echo [1/2] Deleting old alert files from "%ALERT_DIR%"...
) else (
    echo [3/6] Deleting old alert files from "%ALERT_DIR%"...
)
del /f /s /q "%ALERT_DIR%\*" >nul 2>&1
set "DELETE_FAILED=0"
for /r "%ALERT_DIR%" %%F in (*) do (
    echo ERROR: Could not delete "%%F".
    set "DELETE_FAILED=1"
)
if "!DELETE_FAILED!"=="1" (
    if "%RECEIVER_ONLY%"=="1" goto receiver_only_alert_delete_failed
    goto alert_delete_failed
)

if "%RECEIVER_ONLY%"=="1" (
    echo [2/2] Extracting alerts from the selected target logs...
) else (
    echo [4/6] Extracting alerts from the selected target logs...
)
set "LOG_INDEX=0"
set "RECEIVER_FAILURES=0"
if "%INPUT_MODE%"=="ARTIFACTS" (
    for /f "delims=" %%D in ('dir /b /ad "%ARTIFACT_ROOT%\Build-*" 2^>nul ^| sort') do (
        set "CURRENT_LOG=%ARTIFACT_ROOT%\%%D\!LOG_FILE_NAME!"
        if exist "!CURRENT_LOG!" call :receive_log "!CURRENT_LOG!"
    )
) else (
    call :receive_log "%INPUT_LOG%"
)

if "%RECEIVER_ONLY%"=="1" goto receiver_only_done

echo.
echo [5/6] Starting the Detect server...
call :start_server
if errorlevel 1 exit /b 1

echo [6/6] Starting the Detect client...
call :start_client
if errorlevel 1 exit /b 1

if not "!RECEIVER_FAILURES!"=="0" (
    echo.
    echo ERROR: !RECEIVER_FAILURES! of !LOG_COUNT! Receiver invocation^(s^) failed.
    echo Detect was restarted, but the loaded alert set is incomplete.
    exit /b 1
)

echo.
echo Load complete.
echo Input type: !LOG_KIND!
echo Log count:  !LOG_COUNT!
echo Alerts:     %ALERT_DIR%
echo ELF path:   %DETECT_ELF_PATH%
exit /b 0

:receiver_only_prepare
echo Receiver-only mode: Detect server and client state will not be inspected or changed.
goto delete_alerts

:receiver_only_done
if not "!RECEIVER_FAILURES!"=="0" (
    echo.
    echo ERROR: !RECEIVER_FAILURES! of !LOG_COUNT! Receiver invocation^(s^) failed.
    exit /b 1
)
echo.
echo Receiver-only extraction complete.
echo Input type: !LOG_KIND!
echo Log count:  !LOG_COUNT!
echo Alerts:     %ALERT_DIR%
exit /b 0

:discover_artifact_logs
set "QEMU_LOG_COUNT=0"
set "SERIAL_LOG_COUNT=0"
if exist "%ARTIFACT_ROOT%\" (
    for /f "delims=" %%D in ('dir /b /ad "%ARTIFACT_ROOT%\Build-*" 2^>nul ^| sort') do (
        if exist "%ARTIFACT_ROOT%\%%D\qemu.log" set /a "QEMU_LOG_COUNT+=1" >nul
        if exist "%ARTIFACT_ROOT%\%%D\serial.log" set /a "SERIAL_LOG_COUNT+=1" >nul
    )
)

rem F5 writes only qemu_last_session.log and uses build\zephyr\zephyr.elf.
rem Prefer it when it is newer than every file in the suite artifact tree.
powershell.exe -NoProfile -Command "$latest = [DateTime]::MinValue; foreach ($file in @(Get-ChildItem -LiteralPath $env:ARTIFACT_ROOT -Recurse -File -ErrorAction SilentlyContinue)) { if ($file.LastWriteTimeUtc -gt $latest) { $latest = $file.LastWriteTimeUtc } }; $manual = Get-Item -LiteralPath $env:QEMU_FALLBACK_LOG -ErrorAction SilentlyContinue; if ($null -ne $manual -and $manual.LastWriteTimeUtc -gt $latest) { exit 0 }; exit 1"
if not errorlevel 1 (
    set "INPUT_MODE=SINGLE"
    set "INPUT_LOG=%QEMU_FALLBACK_LOG%"
    set "LOG_KIND=manual F5 QEMU"
    set "LOG_COUNT=1"
    set "DETECT_ELF_PATH=%MANUAL_ELF_PATH%"
    if "%CUSTOM_DEVICE_NAME%"=="0" set "DEVICE_NAME=ZephyrQEMU"
    call :check_required_file QEMU_FALLBACK_LOG "%QEMU_FALLBACK_LOG%"
    call :check_required_file MANUAL_ELF_FILE "%MANUAL_ELF_FILE%"
    echo INFO: qemu_last_session.log is newer than the suite artifacts; selecting only the F5 log.
    exit /b 0
)

if not "!QEMU_LOG_COUNT!"=="0" if not "!SERIAL_LOG_COUNT!"=="0" (
    echo ERROR: Both qemu.log and serial.log files exist below ARTIFACT_ROOT.
    echo        The current artifact tree does not identify one unambiguous test type.
    echo        Resolved path: "%ARTIFACT_ROOT%"
    set /a "PREFLIGHT_ERRORS+=1" >nul
    exit /b 0
)

if not "!QEMU_LOG_COUNT!"=="0" (
    set "INPUT_MODE=ARTIFACTS"
    set "LOG_FILE_NAME=qemu.log"
    set "LOG_KIND=QEMU artifact"
    set "LOG_COUNT=!QEMU_LOG_COUNT!"
    if "%CUSTOM_DEVICE_NAME%"=="0" set "DEVICE_NAME=ZephyrQEMU"
    exit /b 0
)

if not "!SERIAL_LOG_COUNT!"=="0" (
    set "INPUT_MODE=ARTIFACTS"
    set "LOG_FILE_NAME=serial.log"
    set "LOG_KIND=hardware serial artifact"
    set "LOG_COUNT=!SERIAL_LOG_COUNT!"
    if "%CUSTOM_DEVICE_NAME%"=="0" set "DEVICE_NAME=ZephyrBoard"
    exit /b 0
)

rem A standalone VS Code QEMU debug session does not create per-image suite
rem artifacts. Preserve the historic qemu_last_session.log behavior for it.
set "INPUT_MODE=SINGLE"
set "INPUT_LOG=%QEMU_FALLBACK_LOG%"
set "LOG_KIND=standalone QEMU fallback"
set "LOG_COUNT=1"
set "DETECT_ELF_PATH=%MANUAL_ELF_PATH%"
if "%CUSTOM_DEVICE_NAME%"=="0" set "DEVICE_NAME=ZephyrQEMU"
call :check_required_file QEMU_FALLBACK_LOG "%QEMU_FALLBACK_LOG%"
call :check_required_file MANUAL_ELF_FILE "%MANUAL_ELF_FILE%"
exit /b 0

:print_selected_logs
if "%INPUT_MODE%"=="ARTIFACTS" (
    for /f "delims=" %%D in ('dir /b /ad "%ARTIFACT_ROOT%\Build-*" 2^>nul ^| sort') do (
        set "CURRENT_LOG=%ARTIFACT_ROOT%\%%D\!LOG_FILE_NAME!"
        if exist "!CURRENT_LOG!" echo   !CURRENT_LOG!
    )
) else (
    echo   %INPUT_LOG%
)
exit /b 0

:receive_log
set /a "LOG_INDEX+=1" >nul
echo.
echo [!LOG_INDEX!/!LOG_COUNT!] "%~1"
findstr /L /C:"[[ DevAlert Data Begins ]]" "%~1" >nul
if errorlevel 1 echo WARNING: This log contains no DFM DevAlert data.
call "%RECEIVER_BAT%" txt --inputfile "%~1" --folder "%ALERT_DIR%" --device_name "%DEVICE_NAME%" --eof exit
if errorlevel 1 (
    echo ERROR: The Receiver failed for "%~1".
    set /a "RECEIVER_FAILURES+=1" >nul
) else (
    echo PASS: Receiver completed for "%~1".
)
exit /b 0

:dry_run
echo DRY RUN - no files, processes, containers, or Docker data will be changed.
echo Would use the !LOG_COUNT! !LOG_KIND! log^(s^) listed above.
if "%RECEIVER_ONLY%"=="1" (
    echo [1/2] Would delete old files below "%ALERT_DIR%".
    echo [2/2] Would invoke the Receiver once per log with device name "%DEVICE_NAME%".
    exit /b 0
)
echo [1/6] Would call "%SERVER_BAT%" cleanup and verify removal of Detect state.
echo [2/6] Would stop python.exe/pythonw.exe processes running percepio-client.py.
echo [3/6] Would delete old files below "%ALERT_DIR%".
echo [4/6] Would invoke the Receiver once per log with device name "%DEVICE_NAME%".
echo [5/6] Would call "%SERVER_BAT%" start and verify all Detect containers.
echo [6/6] Would start "%CLIENT_BAT%" with DETECT_ELF_PATH="%DETECT_ELF_PATH%".
exit /b 0

:usage
echo Usage: %~nx0 [--serial-log FILE] [--device-name NAME] [--receiver-only] [--dry-run]
echo.
echo With no input options, detects the latest suite type from dfm_test_artifacts
echo and loads every Build-*\qemu.log or every Build-*\serial.log file.
echo A newer qemu_last_session.log takes precedence as a manual F5 run and uses
echo build\zephyr\zephyr.elf directly, without changing suite artifacts.
echo Suite alerts select dfm_test_artifacts\Revision\zephyr.elf.
echo --receiver-only only clears and recreates alert-files through the Receiver;
echo it does not inspect, stop, clean, start, or otherwise change Detect server/client state.
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

:alert_delete_failed
echo ERROR: The alert directory could not be emptied. No logs were loaded.
echo Attempting to restart the Detect server and client before exiting...
call :start_server
if not errorlevel 1 call :start_client
exit /b 1

:receiver_only_alert_delete_failed
echo ERROR: The alert directory could not be emptied. No logs were loaded.
echo Detect server and client state was not changed.
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
