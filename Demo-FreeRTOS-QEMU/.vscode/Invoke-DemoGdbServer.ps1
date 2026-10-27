param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Start', 'Stop')]
    [string] $Action,

    [string] $CMakePath = 'cmake',

    [string] $BuildDirectory,

    [string] $QemuWindowsRuntimePath,

    [string] $LogPath,

    [string] $GdbPath,

    [string] $OpenOcdPath,

    [string] $OpenOcdScripts,

    [int] $Port = 1234
)

$ErrorActionPreference = 'Stop'

function Normalize-QemuLogLineEndings {
    if ([string]::IsNullOrWhiteSpace($LogPath) -or
        -not (Test-Path -LiteralPath $LogPath -PathType Leaf)) {
        return
    }

    $inputBytes = [IO.File]::ReadAllBytes($LogPath)
    $outputStream = [IO.MemoryStream]::new($inputBytes.Length)

    for ($index = 0; $index -lt $inputBytes.Length; $index++) {
        if ($inputBytes[$index] -eq 13) {
            $nextIndex = $index + 1
            while ($nextIndex -lt $inputBytes.Length -and
                   $inputBytes[$nextIndex] -eq 13) {
                $nextIndex++
            }

            if ($nextIndex -lt $inputBytes.Length -and
                $inputBytes[$nextIndex] -eq 10) {
                $outputStream.WriteByte(13)
                $outputStream.WriteByte(10)
                $index = $nextIndex
                continue
            }
        }

        $outputStream.WriteByte($inputBytes[$index])
    }

    if ($outputStream.Length -ne $inputBytes.Length) {
        [IO.File]::WriteAllBytes($LogPath, $outputStream.ToArray())
    }

    $outputStream.Dispose()
}

function Stop-DemoGdbServer {
    $listeners = @(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
    $serverProcessIds = @()

    foreach ($processId in @($listeners.OwningProcess | Sort-Object -Unique)) {
        $serverProcess = Get-Process -Id $processId -ErrorAction SilentlyContinue
        if ($null -eq $serverProcess) {
            continue
        }

        if ($serverProcess.ProcessName -notlike 'qemu-system-*' -and $serverProcess.ProcessName -ne 'openocd') {
            throw "Port $Port is used by '$($serverProcess.ProcessName)' (PID $processId), not a demo GDB server. Refusing to stop it."
        }

        $serverProcessIds += $processId
    }

    if (-not [string]::IsNullOrWhiteSpace($BuildDirectory)) {
        $pidFile = Join-Path $BuildDirectory 'qemu.pid'
        if (Test-Path -LiteralPath $pidFile -PathType Leaf) {
            $pidFileProcessId = 0
            if ([int]::TryParse((Get-Content -Raw -LiteralPath $pidFile).Trim(), [ref] $pidFileProcessId)) {
                $pidFileProcess = Get-Process -Id $pidFileProcessId -ErrorAction SilentlyContinue
                if ($null -ne $pidFileProcess -and $pidFileProcess.ProcessName -like 'qemu-system-*') {
                    $serverProcessIds += $pidFileProcessId
                }
            }
        }
    }

    $serverProcessIds = @($serverProcessIds | Sort-Object -Unique)
    if ($serverProcessIds.Count -eq 0) {
        return
    }

    if (-not [string]::IsNullOrWhiteSpace($GdbPath) -and
        (Test-Path -LiteralPath $GdbPath -PathType Leaf)) {
        Write-Host "Stopping demo GDB server gracefully on port $Port."
        $shutdownCommand = 'monitor quit'
        if (@($serverProcessIds | ForEach-Object { Get-Process -Id $_ -ErrorAction SilentlyContinue } |
                Where-Object ProcessName -eq 'openocd').Count -gt 0) {
            $shutdownCommand = 'monitor shutdown'
        }
        $gdbArguments = @('-q', '-batch')
        $elfPath = Join-Path $BuildDirectory 'Demo-FreeRTOS-QEMU.elf'
        if (Test-Path -LiteralPath $elfPath -PathType Leaf) {
            $gdbArguments += $elfPath
        }
        $gdbArguments += @(
            '-ex',
            'set tcp connect-timeout 2',
            '-ex',
            "target remote localhost:$Port",
            '-ex',
            $shutdownCommand
        )

        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        & $GdbPath @gdbArguments 2>&1 | Out-Null
        $ErrorActionPreference = $previousErrorActionPreference

        for ($attempt = 0; $attempt -lt 20; $attempt++) {
            $runningServerProcesses = @($serverProcessIds | ForEach-Object {
                Get-Process -Id $_ -ErrorAction SilentlyContinue
            })
            if ($runningServerProcesses.Count -eq 0) {
                return
            }

            Start-Sleep -Milliseconds 100
        }
    }

    foreach ($processId in $serverProcessIds) {
        $serverProcess = Get-Process -Id $processId -ErrorAction SilentlyContinue
        if ($null -ne $serverProcess -and ($serverProcess.ProcessName -like 'qemu-system-*' -or $serverProcess.ProcessName -eq 'openocd')) {
            Write-Host "Force-stopping demo GDB server (PID $processId) on port $Port."
            Stop-Process -Id $processId -Force
        }
    }

    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        if (-not (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)) {
            return
        }

        Start-Sleep -Milliseconds 100
    }

    throw "Port $Port is still in use after stopping the previous demo GDB server."
}

if ($Action -eq 'Stop') {
    Stop-DemoGdbServer
    exit 0
}

if ([string]::IsNullOrWhiteSpace($BuildDirectory) -or
    -not (Test-Path -LiteralPath $BuildDirectory -PathType Container)) {
    throw "The CMake build directory was not found at '$BuildDirectory'."
}

$startInfo = [System.Diagnostics.ProcessStartInfo]::new()
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true
$startInfo.WorkingDirectory = $BuildDirectory

$cachePath = Join-Path $BuildDirectory 'CMakeCache.txt'
$hardwareTarget = Select-String -LiteralPath $cachePath -Pattern '^DEMO_TARGET:STRING=b_u585i_iot02a$' -Quiet
if ($hardwareTarget) {
    # STM32CubeIDE bundles ST's OpenOCD fork and its STM32U5 scripts.
    $cubeIdeRoots = @(Get-ChildItem -LiteralPath 'C:/ST' -Directory -Filter 'STM32CubeIDE_*' -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending)
    if (-not $OpenOcdPath) {
        $onPath = Get-Command openocd -CommandType Application -ErrorAction SilentlyContinue
        if ($onPath) { $OpenOcdPath = $onPath.Source }
        foreach ($cubeIdeRoot in $cubeIdeRoots) {
            if ($OpenOcdPath) { break }
            $OpenOcdPath = Get-ChildItem -Path "$($cubeIdeRoot.FullName)/STM32CubeIDE/plugins/com.st.stm32cube.ide.mcu.externaltools.openocd.win32_*/tools/bin/openocd.exe" -ErrorAction SilentlyContinue |
                Select-Object -First 1 -ExpandProperty FullName
        }
    }
    if (-not $OpenOcdScripts) {
        foreach ($cubeIdeRoot in $cubeIdeRoots) {
            $OpenOcdScripts = Get-ChildItem -Path "$($cubeIdeRoot.FullName)/STM32CubeIDE/plugins/com.st.stm32cube.ide.mcu.debug.openocd_*/resources/openocd/st_scripts" -Directory -ErrorAction SilentlyContinue |
                Select-Object -First 1 -ExpandProperty FullName
            if ($OpenOcdScripts) { break }
        }
    }
    if (-not $OpenOcdPath -or -not $OpenOcdScripts) {
        throw 'Set freertos.openOcdPath and freertos.openOcdScripts in .vscode/settings.json, or install STM32CubeIDE under C:/ST.'
    }
    $startInfo.FileName = $OpenOcdPath
    $boardConfig = Join-Path $PSScriptRoot '../cmake/openocd/b_u585i_iot02a.cfg'
    $serverArguments = @('-s', $OpenOcdScripts, '-f', $boardConfig, '-c', "gdb_port $Port", '-c', 'bindto 127.0.0.1')
}
else {
    if (-not [string]::IsNullOrWhiteSpace($QemuWindowsRuntimePath)) {
        $QemuWindowsRuntimePath = [Environment]::ExpandEnvironmentVariables($QemuWindowsRuntimePath)
        if (Test-Path -LiteralPath $QemuWindowsRuntimePath -PathType Container) {
            $env:PATH = $env:PATH + [IO.Path]::PathSeparator + $QemuWindowsRuntimePath
        }
        else {
            Write-Warning "The configured QEMU Windows runtime directory does not exist: '$QemuWindowsRuntimePath'."
        }
    }
    if ([string]::IsNullOrWhiteSpace($LogPath)) {
        throw 'The QEMU log path was not provided.'
    }
    $LogPath = [Environment]::ExpandEnvironmentVariables($LogPath)
    if (-not (Test-Path -LiteralPath (Split-Path -Parent $LogPath) -PathType Container)) {
        throw "The QEMU log directory was not found for '$LogPath'."
    }
    $cmakeCommand = Get-Command $CMakePath -CommandType Application -ErrorAction Stop
    $startInfo.FileName = $cmakeCommand.Source
    $serverArguments = @('--build', $BuildDirectory, '--target', 'debugserver_qemu_logged')
}

# Windows PowerShell 5.1 does not expose ProcessStartInfo.ArgumentList.
$startInfo.Arguments = ($serverArguments | ForEach-Object {
    '"' + $_.Replace('"', '\"') + '"'
}) -join ' '

$serverProcess = [System.Diagnostics.Process]::Start($startInfo)
$serverReady = $false

for ($attempt = 0; $attempt -lt 300 -and -not $serverProcess.HasExited; $attempt++) {
    if (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue) {
        $serverReady = $true
        break
    }

    Start-Sleep -Milliseconds 100
}

if (-not $serverReady) {
    if (-not $serverProcess.HasExited) {
        Stop-Process -Id $serverProcess.Id -Force
    }

    $serverProcess.WaitForExit()
    if (-not $hardwareTarget) { Normalize-QemuLogLineEndings }
    throw "Demo GDB server did not start on port $Port (exit code: $($serverProcess.ExitCode))."
}

Write-Host "Demo GDB server is listening on port $Port."
$serverProcess.WaitForExit()
if (-not $hardwareTarget) { Normalize-QemuLogLineEndings }
exit $serverProcess.ExitCode
