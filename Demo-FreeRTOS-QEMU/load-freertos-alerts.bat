@echo off
setlocal EnableExtensions EnableDelayedExpansion

for %%I in ("%~dp0.") do set "PROJECT_ROOT=%%~fI"
set "DETECT_ROOT=C:\src\DetectRepo"
set "ALERT_DIR=%PROJECT_ROOT%\freertos-test"
set "SERVER_DIR=%DETECT_ROOT%\percepio-server"
set "SERVER_BAT=%SERVER_DIR%\percepio-server.bat"
set "RECEIVER_DIR=%DETECT_ROOT%\percepio-receiver"
set "RECEIVER_BAT=%RECEIVER_DIR%\percepio-receiver.bat"
set "CLIENT_DIR=%DETECT_ROOT%\percepio-client"
set "CLIENT_BAT=%CLIENT_DIR%\percepio-client.bat"
set "SERVER_CONTAINERS=detect-alert-sender detect-frontend detect-backend detect-database"
set "DATABASE_VOLUME=percepio_database"
set "DEMO_ELF_FILE=%PROJECT_ROOT%\build\debug\Demo-FreeRTOS-QEMU.elf"

rem These variables are inherited by the Detect server and client processes.
set "DETECT_ALERT_DIR=%ALERT_DIR%"
rem The F5 session always uses the current demo image.
set "DETECT_ELF_PATH=%DEMO_ELF_FILE%"

set "DRY_RUN=0"
set "RECEIVER_ONLY=0"
set "RESET_AND_RESTART_SERVER=0"
set "INPUT_LOG=%PROJECT_ROOT%\qemu_last_session.log"
set "LOG_KIND=manual F5 QEMU"
set "LOG_COUNT=1"
set "DEVICE_NAME=FreeRTOSQEMU"

:parse_args
if "%~1"=="" goto args_done
if /I "%~1"=="--dry-run" (
    set "DRY_RUN=1"
) else if /I "%~1"=="--receiver-only" (
    set "RECEIVER_ONLY=1"
) else if /I "%~1"=="--reset_and_restart_server" (
    set "RESET_AND_RESTART_SERVER=1"
) else if /I "%~1"=="--device-name" (
    if "%~2"=="" goto missing_argument
    set "DEVICE_NAME=%~2"
    shift
) else (
    echo ERROR: Unexpected argument: %~1
    goto usage
)
shift
goto parse_args

:args_done
if "%RECEIVER_ONLY%"=="1" if "%RESET_AND_RESTART_SERVER%"=="1" (
    echo ERROR: --receiver-only cannot be combined with --reset_and_restart_server.
    goto usage
)
set "STOP_CLIENT_STEP=1"
set "DELETE_ALERTS_STEP=2"
set "RECEIVE_STEP=3"
set "START_CLIENT_STEP=4"
if "%RESET_AND_RESTART_SERVER%"=="1" (
    set "STOP_CLIENT_STEP=2"
    set "DELETE_ALERTS_STEP=3"
    set "RECEIVE_STEP=4"
    set "START_CLIENT_STEP=6"
)
set "TOTAL_STEPS=%START_CLIENT_STEP%"
if "%DETECT_CLIENT_TEXT_OUTPUT%"=="1" set /a "TOTAL_STEPS+=1" >nul

echo Checking configured paths and captured demo log...
set "PREFLIGHT_ERRORS=0"
call :check_required_directory PROJECT_ROOT "%PROJECT_ROOT%"
call :check_required_directory DETECT_ROOT "%DETECT_ROOT%"
call :check_required_directory RECEIVER_DIR "%RECEIVER_DIR%"
call :check_required_file RECEIVER_BAT "%RECEIVER_BAT%"
call :check_directory_target ALERT_DIR "%ALERT_DIR%"
if "%RECEIVER_ONLY%"=="0" (
    call :check_required_directory CLIENT_DIR "%CLIENT_DIR%"
    call :check_required_file CLIENT_BAT "%CLIENT_BAT%"
    call :check_required_file DETECT_ELF_PATH "%DETECT_ELF_PATH%"
)
if "%RESET_AND_RESTART_SERVER%"=="1" (
    call :check_required_directory SERVER_DIR "%SERVER_DIR%"
    call :check_required_file SERVER_BAT "%SERVER_BAT%"
)

call :check_required_file INPUT_LOG "%INPUT_LOG%"

if not "!PREFLIGHT_ERRORS!"=="0" (
    echo.
    echo ERROR: Path and input validation found !PREFLIGHT_ERRORS! problem^(s^). Nothing was changed.
    exit /b 1
)

echo Path preflight passed. Selected !LOG_COUNT! !LOG_KIND! log^(s^).
echo   %INPUT_LOG%
if "%RECEIVER_ONLY%"=="0" echo ELF: %DETECT_ELF_PATH%
echo.

if "%DRY_RUN%"=="1" goto dry_run

call :ensure_directory ALERT_DIR "%ALERT_DIR%"
if errorlevel 1 exit /b 1

if "%RECEIVER_ONLY%"=="1" goto receiver_only_prepare
if "%RESET_AND_RESTART_SERVER%"=="0" (
    echo Using the existing Detect server; cleanup and server restart are disabled.
    goto stop_client
)

docker info >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is unavailable. Start Docker Desktop and try again.
    exit /b 1
)

echo [1/!TOTAL_STEPS!] Cleaning the Detect server and its persistent database...
pushd "%SERVER_DIR%"
rem Redirect confirmation from a file. A pipe into CALL can lose stdin when
rem cmd.exe starts the nested batch file, causing cleanup to be aborted.
set "CONFIRM_FILE=%TEMP%\load_freertos_alerts_cleanup_!RANDOM!_!RANDOM!.txt"
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

:stop_client
echo [!STOP_CLIENT_STEP!/!TOTAL_STEPS!] Stopping any running Detect client...
powershell.exe -NoProfile -Command "$stopped = 0; $processes = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue); foreach ($process in $processes) { if ((@('python.exe', 'pythonw.exe') -contains $process.Name) -and ($process.CommandLine -match 'percepio-client[.]py')) { Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue; $stopped++ } }; Write-Host ('      Stopped {0} client process(es).' -f $stopped)"

:delete_alerts
if "%RECEIVER_ONLY%"=="1" (
    echo [1/2] Deleting old alert files from "%ALERT_DIR%"...
) else (
    echo [!DELETE_ALERTS_STEP!/!TOTAL_STEPS!] Deleting old alert files from "%ALERT_DIR%"...
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
    echo [!RECEIVE_STEP!/!TOTAL_STEPS!] Extracting alerts from the selected target logs...
)
set "LOG_INDEX=0"
set "RECEIVER_FAILURES=0"
call :receive_log "%INPUT_LOG%"

if "%RECEIVER_ONLY%"=="1" goto receiver_only_done

echo.
if "%RESET_AND_RESTART_SERVER%"=="1" (
    echo [5/!TOTAL_STEPS!] Starting the Detect server...
    call :start_server
    if errorlevel 1 exit /b 1
)

if "%DETECT_CLIENT_TEXT_OUTPUT%"=="1" (
    echo [!START_CLIENT_STEP!/!TOTAL_STEPS!] Exporting all alert payloads to text...
) else (
    echo [!START_CLIENT_STEP!/!TOTAL_STEPS!] Starting the Detect client...
)
call :start_client
if errorlevel 1 exit /b 1

if not "!RECEIVER_FAILURES!"=="0" (
    echo.
    echo ERROR: !RECEIVER_FAILURES! of !LOG_COUNT! Receiver invocation^(s^) failed.
    echo The loaded alert set is incomplete.
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
if "%RESET_AND_RESTART_SERVER%"=="1" (
    echo [1/!TOTAL_STEPS!] Would call "%SERVER_BAT%" cleanup and verify removal of Detect state.
) else (
    echo Would use the existing Detect server without cleanup or server restart.
)
echo [!STOP_CLIENT_STEP!/!TOTAL_STEPS!] Would stop python.exe/pythonw.exe processes running percepio-client.py.
echo [!DELETE_ALERTS_STEP!/!TOTAL_STEPS!] Would delete old files below "%ALERT_DIR%".
echo [!RECEIVE_STEP!/!TOTAL_STEPS!] Would invoke the Receiver once per log with device name "%DEVICE_NAME%".
if "%RESET_AND_RESTART_SERVER%"=="1" echo [5/!TOTAL_STEPS!] Would call "%SERVER_BAT%" start and verify all Detect containers.
if "%DETECT_CLIENT_TEXT_OUTPUT%"=="1" (
    echo [!START_CLIENT_STEP!/!TOTAL_STEPS!] Would run "%CLIENT_BAT%" synchronously in text-output mode.
    echo [!TOTAL_STEPS!/!TOTAL_STEPS!] Would then start "%CLIENT_BAT%" in normal interactive mode with DETECT_ELF_PATH="%DETECT_ELF_PATH%".
) else (
    echo [!START_CLIENT_STEP!/!TOTAL_STEPS!] Would start "%CLIENT_BAT%" with DETECT_ELF_PATH="%DETECT_ELF_PATH%".
)
exit /b 0

:usage
echo Usage: %~nx0 [--device-name NAME] [--receiver-only] [--reset_and_restart_server] [--dry-run]
echo.
echo Loads qemu_last_session.log from the latest F5 session
echo using the configured demo ELF image. No other log directories are searched.
echo By default, the server must already be running; its database is retained.
echo --reset_and_restart_server runs server cleanup, deletes the database, and
echo starts the server again. It cannot be combined with --receiver-only.
echo Both normal modes replace freertos-test alerts and restart the Detect client.
echo --receiver-only only clears and recreates freertos-test through the Receiver;
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
if "%RESET_AND_RESTART_SERVER%"=="1" (
    echo Attempting to restart the Detect server before exiting...
    call :start_server
    if errorlevel 1 exit /b 1
)
echo Attempting to restart the Detect client before exiting...
call :start_client
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
if "%DETECT_CLIENT_TEXT_OUTPUT%"=="1" (
    echo       Text-output mode: processing every alert payload synchronously.
    pushd "%CLIENT_DIR%"
    call "%CLIENT_BAT%"
    set "CLIENT_RESULT=!ERRORLEVEL!"
    popd
    if not "!CLIENT_RESULT!"=="0" (
        echo ERROR: The Detect client text export failed with exit code !CLIENT_RESULT!.
        exit /b 1
    )
    rem The export process has completed. Start a fresh normal client for the
    rem dashboard, retaining DETECT_ALERT_DIR and DETECT_ELF_PATH but removing
    rem the one-shot text-export variables from the child environment.
    set "DETECT_CLIENT_TEXT_OUTPUT="
    set "DETECT_CLIENT_OUTPUT_DIR="
    set "DETECT_CLIENT_RUN_ID="
    echo [!TOTAL_STEPS!/!TOTAL_STEPS!] Starting the Detect client in normal interactive mode...
)
powershell.exe -NoProfile -Command "$ErrorActionPreference = 'Stop'; $client = Start-Process -FilePath $env:ComSpec -ArgumentList '/d','/c','percepio-client.bat' -WorkingDirectory $env:CLIENT_DIR -WindowStyle Normal -PassThru; Write-Host ('      Started Detect client process {0}.' -f $client.Id)"
if errorlevel 1 (
    echo ERROR: The Detect client could not be started from "%CLIENT_DIR%".
    exit /b 1
)
exit /b 0
