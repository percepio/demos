param(
    [string]$Elf = "$PSScriptRoot\..\build\debug\Demo-FreeRTOS-QEMU.elf",
    [string]$Qemu = 'C:\Users\johan\zephyr-sdk-1.0.1\hosttools\qemu\qemu-system-arm.exe'
)

$ErrorActionPreference = 'Stop'

$elfPath = (Resolve-Path -LiteralPath $Elf -ErrorAction Stop).Path
$qemuPath = (Resolve-Path -LiteralPath $Qemu -ErrorAction Stop).Path
$runtimeElfPath = Join-Path (Split-Path -Parent $elfPath) 'Demo-FreeRTOS-QEMU.qemu.elf'
$pidFile = Join-Path $PSScriptRoot 'qemu-gdb.pid'
$stdoutLog = Join-Path (Split-Path -Parent $PSScriptRoot) 'qemu-gdb.log'
$stderrLog = Join-Path (Split-Path -Parent $PSScriptRoot) 'qemu-gdb.error.log'
$serialLogPath = $stdoutLog.Replace('\\', '/')

function Get-ListenerProcessIds {
    param([int]$LocalPort)

    $result = @()
    $portPattern = ':' + [Regex]::Escape($LocalPort.ToString()) + '$'
    foreach ($line in & "$env:SystemRoot\System32\netstat.exe" -ano -p tcp) {
        $fields = @($line.Trim() -split '\s+')
        if ($fields.Count -ne 5 -or
            $fields[0] -ne 'TCP' -or
            $fields[1] -notmatch $portPattern -or
            $fields[3] -ne 'LISTENING') {
            continue
        }

        $listenerProcessId = 0
        if ([int]::TryParse($fields[4], [ref]$listenerProcessId)) {
            $result += $listenerProcessId
        }
    }
    return @($result | Sort-Object -Unique)
}

# Always clean up a previous project instance. The stop script also finds an
# orphaned instance that owns the GDB port when its PID file has gone stale.
& "$PSScriptRoot\Stop-QemuGdbServer.ps1" -Qemu $qemuPath -Elf $elfPath
Copy-Item -LiteralPath $elfPath -Destination $runtimeElfPath -Force

$gitMingw = 'C:\Program Files\Git\mingw64\bin'
if (Test-Path -LiteralPath $gitMingw -PathType Container) {
    $env:PATH = "$gitMingw;$env:PATH"
}

$arguments = @(
    '-machine', 'mps2-an385',
    '-cpu', 'cortex-m3',
    '-kernel', $runtimeElfPath,
    '-display', 'none',
    '-monitor', 'none',
    '-chardev', "file,id=qemu_serial,path=$serialLogPath",
    '-serial', 'chardev:qemu_serial',
    '-icount', 'shift=6,align=on,sleep=on',
    '-rtc', 'clock=vm',
    '-net', 'none',
    '-S', '-gdb', 'tcp::1234'
)

$process = Start-Process -FilePath $qemuPath -ArgumentList $arguments `
    -RedirectStandardError $stderrLog `
    -WindowStyle Hidden -PassThru
Set-Content -LiteralPath $pidFile -Value $process.Id -NoNewline

try {
    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    do {
        if ($process.HasExited) {
            throw "QEMU exited before opening GDB port 1234. See $stderrLog"
        }

        $listenerProcessIds = @(Get-ListenerProcessIds -LocalPort 1234)
        if ($listenerProcessIds -contains $process.Id) {
            # A listening TCP socket appears slightly before QEMU's GDB stub is
            # ready to process its first remote-protocol packet. VS Code has an
            # already-loaded debug adapter and can otherwise win that race.
            Start-Sleep -Milliseconds 1000
            $listenerProcessIds = @(Get-ListenerProcessIds -LocalPort 1234)
            if ($process.HasExited -or $listenerProcessIds -notcontains $process.Id) {
                throw 'QEMU stopped listening on GDB port 1234 during startup.'
            }

            Write-Output "QEMU PID $($process.Id) is waiting for GDB on localhost:1234."
            Write-Output 'QEMU GDB server is listening on port 1234.'
            # This is a normal, finite VS Code pre-launch task. QEMU remains
            # detached and is stopped by the post-debug task or the next build.
            exit 0
        }

        if ($listenerProcessIds.Count -gt 0) {
            throw "GDB port 1234 is owned by PID $($listenerProcessIds -join ', '), not the new QEMU PID $($process.Id)."
        }

        Start-Sleep -Milliseconds 100
    } while ([DateTime]::UtcNow -lt $deadline)

    throw 'Timed out while waiting for QEMU GDB port 1234.'
}
catch {
    if (-not $process.HasExited) {
        Stop-Process -Id $process.Id -Force
        $process.WaitForExit()
    }
    Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
    throw
}
