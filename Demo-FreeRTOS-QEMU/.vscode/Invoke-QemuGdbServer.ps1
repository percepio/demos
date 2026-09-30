param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Start', 'Stop')]
    [string] $Action,

    [string] $CMakePath = 'cmake',

    [string] $BuildDirectory,

    [string] $QemuWindowsRuntimePath,

    [string] $LogPath,

    [string] $GdbPath,

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

$cmakeCommand = Get-Command $CMakePath -CommandType Application -ErrorAction Stop

if ([string]::IsNullOrWhiteSpace($BuildDirectory) -or
    -not (Test-Path -LiteralPath $BuildDirectory -PathType Container)) {
    throw "The CMake build directory was not found at '$BuildDirectory'."
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

if ([string]::IsNullOrWhiteSpace($LogPath)) {
    throw 'The QEMU log path was not provided.'
}

$LogPath = [Environment]::ExpandEnvironmentVariables($LogPath)
$logDirectory = Split-Path -Parent $LogPath
if (-not (Test-Path -LiteralPath $logDirectory -PathType Container)) {
    throw "The QEMU log directory was not found at '$logDirectory'."
}

$cmakeArguments = @(
    '--build',
    $BuildDirectory,
    '--target',
    'debugserver_qemu_logged'
)

$startInfo = [System.Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = $cmakeCommand.Source
$startInfo.UseShellExecute = $false
$startInfo.WorkingDirectory = $BuildDirectory

# Windows PowerShell 5.1 does not expose ProcessStartInfo.ArgumentList.
$startInfo.Arguments = ($cmakeArguments | ForEach-Object {
    '"' + $_.Replace('"', '\"') + '"'
}) -join ' '

$cmakeProcess = [System.Diagnostics.Process]::Start($startInfo)
$serverReady = $false

for ($attempt = 0; $attempt -lt 300 -and -not $cmakeProcess.HasExited; $attempt++) {
    if (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue) {
        $serverReady = $true
        break
    }

    Start-Sleep -Milliseconds 100
}

if (-not $serverReady) {
    if (-not $cmakeProcess.HasExited) {
        Stop-Process -Id $cmakeProcess.Id -Force
    }

    $cmakeProcess.WaitForExit()
    Normalize-QemuLogLineEndings
    throw "QEMU GDB server did not start on port $Port (CMake exit code: $($cmakeProcess.ExitCode))."
}

Write-Host "QEMU GDB server is listening on port $Port."
$cmakeProcess.WaitForExit()
Normalize-QemuLogLineEndings
exit $cmakeProcess.ExitCode
