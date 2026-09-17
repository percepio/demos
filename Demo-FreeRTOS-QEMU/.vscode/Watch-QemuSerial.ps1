param(
    [string]$Log = "$PSScriptRoot\..\qemu_last_session.log",
    [string]$Qemu = 'C:\Users\johan\zephyr-sdk-1.0.1\hosttools\qemu\qemu-system-arm.exe'
)

$ErrorActionPreference = 'Stop'

$logPath = [IO.Path]::GetFullPath($Log)
$qemuPath = (Resolve-Path -LiteralPath $Qemu -ErrorAction Stop).Path
$pidFile = Join-Path $PSScriptRoot 'qemu-gdb.pid'

Write-Output 'QEMU UART monitor starting.'

$pidText = (Get-Content -LiteralPath $pidFile -Raw -ErrorAction Stop).Trim()
$qemuProcessId = 0
if (-not [int]::TryParse($pidText, [ref]$qemuProcessId)) {
    throw "Invalid QEMU PID in $pidFile"
}

$qemuProcess = Get-Process -Id $qemuProcessId -ErrorAction Stop
if ($qemuProcess.Path -ne $qemuPath) {
    throw "PID $qemuProcessId is not the configured QEMU process."
}

$deadline = [DateTime]::UtcNow.AddSeconds(5)
while (-not (Test-Path -LiteralPath $logPath -PathType Leaf)) {
    if ($qemuProcess.HasExited) {
        throw 'QEMU exited before creating its UART log.'
    }
    if ([DateTime]::UtcNow -ge $deadline) {
        throw "Timed out waiting for QEMU UART log $logPath"
    }
    Start-Sleep -Milliseconds 50
}

$stream = [IO.FileStream]::new(
    $logPath,
    [IO.FileMode]::Open,
    [IO.FileAccess]::Read,
    [IO.FileShare]::ReadWrite
)

try {
    Write-Output "QEMU UART monitor is ready. Output is also saved to $logPath"

    $buffer = [byte[]]::new(4096)
    do {
        $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
        if ($bytesRead -gt 0) {
            [Console]::Out.Write([Text.Encoding]::UTF8.GetString($buffer, 0, $bytesRead))
            [Console]::Out.Flush()
        }
        else {
            Start-Sleep -Milliseconds 50
            $qemuProcess.Refresh()
        }
    } while (-not $qemuProcess.HasExited -or $stream.Position -lt $stream.Length)
}
finally {
    $stream.Dispose()
}
