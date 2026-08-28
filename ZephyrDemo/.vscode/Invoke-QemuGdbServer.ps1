param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Start', 'Stop')]
    [string] $Action,

    [string] $PythonPath,

    [string] $BuildDirectory,

    [string] $QemuWindowsRuntimePath,

    [string] $GdbPath,

    [int] $Port = 1234
)

$ErrorActionPreference = 'Stop'

function Stop-QemuGdbServer {
    $listeners = @(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
    $qemuProcessIds = @()

    foreach ($processId in @($listeners.OwningProcess | Sort-Object -Unique)) {
        $qemuProcess = Get-Process -Id $processId -ErrorAction SilentlyContinue
        if ($null -eq $qemuProcess) {
            continue
        }

        if ($qemuProcess.ProcessName -notlike 'qemu-system-*') {
            throw "Port $Port is used by '$($qemuProcess.ProcessName)' (PID $processId), not QEMU. Refusing to stop it."
        }

        $qemuProcessIds += $processId
    }

    if (-not [string]::IsNullOrWhiteSpace($BuildDirectory)) {
        $pidFile = Join-Path $BuildDirectory 'qemu.pid'
        if (Test-Path -LiteralPath $pidFile -PathType Leaf) {
            $pidFileProcessId = 0
            if ([int]::TryParse((Get-Content -Raw -LiteralPath $pidFile).Trim(), [ref] $pidFileProcessId)) {
                $pidFileProcess = Get-Process -Id $pidFileProcessId -ErrorAction SilentlyContinue
                if ($null -ne $pidFileProcess -and $pidFileProcess.ProcessName -like 'qemu-system-*') {
                    $qemuProcessIds += $pidFileProcessId
                }
            }
        }
    }

    $qemuProcessIds = @($qemuProcessIds | Sort-Object -Unique)
    if ($qemuProcessIds.Count -eq 0) {
        return
    }

    if (-not [string]::IsNullOrWhiteSpace($GdbPath) -and
        (Test-Path -LiteralPath $GdbPath -PathType Leaf)) {
        Write-Host "Stopping QEMU GDB server gracefully on port $Port."
        $gdbArguments = @('-q', '-batch')
        $elfPath = Join-Path $BuildDirectory 'zephyr\zephyr.elf'
        if (Test-Path -LiteralPath $elfPath -PathType Leaf) {
            $gdbArguments += $elfPath
        }
        $gdbArguments += @(
            '-ex',
            'set tcp connect-timeout 2',
            '-ex',
            "target remote localhost:$Port",
            '-ex',
            'monitor quit'
        )

        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        & $GdbPath @gdbArguments 2>&1 | Out-Null
        $ErrorActionPreference = $previousErrorActionPreference

        for ($attempt = 0; $attempt -lt 20; $attempt++) {
            $runningQemuProcesses = @($qemuProcessIds | ForEach-Object {
                Get-Process -Id $_ -ErrorAction SilentlyContinue
            })
            if ($runningQemuProcesses.Count -eq 0) {
                return
            }

            Start-Sleep -Milliseconds 100
        }
    }

    foreach ($processId in $qemuProcessIds) {
        $qemuProcess = Get-Process -Id $processId -ErrorAction SilentlyContinue
        if ($null -ne $qemuProcess -and $qemuProcess.ProcessName -like 'qemu-system-*') {
            Write-Host "Force-stopping QEMU GDB server (PID $processId) on port $Port."
            Stop-Process -Id $processId -Force
        }
    }

    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        if (-not (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)) {
            return
        }

        Start-Sleep -Milliseconds 100
    }

    throw "Port $Port is still in use after stopping the previous QEMU GDB server."
}

if ($Action -eq 'Stop') {
    Stop-QemuGdbServer
    exit 0
}

if ([string]::IsNullOrWhiteSpace($PythonPath) -or
    -not (Test-Path -LiteralPath $PythonPath -PathType Leaf)) {
    throw "Python was not found at '$PythonPath'."
}

if ([string]::IsNullOrWhiteSpace($BuildDirectory) -or
    -not (Test-Path -LiteralPath $BuildDirectory -PathType Container)) {
    throw "The Zephyr build directory was not found at '$BuildDirectory'."
}

if (-not [string]::IsNullOrWhiteSpace($QemuWindowsRuntimePath)) {
    $QemuWindowsRuntimePath = [Environment]::ExpandEnvironmentVariables($QemuWindowsRuntimePath)

    if (Test-Path -LiteralPath $QemuWindowsRuntimePath -PathType Container) {
        $env:PATH = $env:PATH + [IO.Path]::PathSeparator + $QemuWindowsRuntimePath
    }
    else {
        Write-Warning "The configured QEMU Windows runtime directory does not exist: '$QemuWindowsRuntimePath'."
    }
}

$westArguments = @(
    '-m',
    'west',
    'build',
    '-d',
    $BuildDirectory,
    '-t',
    'debugserver_qemu'
)

$startInfo = [System.Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = $PythonPath
$startInfo.UseShellExecute = $false
$startInfo.WorkingDirectory = $BuildDirectory

# Windows PowerShell 5.1 does not expose ProcessStartInfo.ArgumentList.
$startInfo.Arguments = ($westArguments | ForEach-Object {
    '"' + $_.Replace('"', '\"') + '"'
}) -join ' '

$westProcess = [System.Diagnostics.Process]::Start($startInfo)
$serverReady = $false
$qemuPidFile = Join-Path $BuildDirectory 'qemu.pid'
$launchStartedAt = Get-Date

for ($attempt = 0; $attempt -lt 300 -and -not $westProcess.HasExited; $attempt++) {
    if (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue) {
        $serverReady = $true
        break
    }

    if (Test-Path -LiteralPath $qemuPidFile -PathType Leaf) {
        $qemuProcessId = 0
        if ([int]::TryParse((Get-Content -Raw -LiteralPath $qemuPidFile).Trim(), [ref] $qemuProcessId)) {
            $qemuProcess = Get-Process -Id $qemuProcessId -ErrorAction SilentlyContinue
            if ($null -ne $qemuProcess -and
                $qemuProcess.ProcessName -like 'qemu-system-*' -and
                $qemuProcess.StartTime -ge $launchStartedAt.AddSeconds(-2)) {
                Start-Sleep -Milliseconds 250
                $serverReady = -not $qemuProcess.HasExited
                if ($serverReady) {
                    break
                }
            }
        }
    }

    Start-Sleep -Milliseconds 100
}

if (-not $serverReady) {
    if (-not $westProcess.HasExited) {
        Stop-Process -Id $westProcess.Id -Force
    }

    $westProcess.WaitForExit()
    throw "QEMU GDB server did not start on port $Port (west exit code: $($westProcess.ExitCode))."
}

Write-Host "QEMU GDB server is listening on port $Port."
$westProcess.WaitForExit()
exit $westProcess.ExitCode
