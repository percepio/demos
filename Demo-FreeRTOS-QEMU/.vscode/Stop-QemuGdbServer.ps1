param(
    [string]$Qemu = 'C:\Users\johan\zephyr-sdk-1.0.1\hosttools\qemu\qemu-system-arm.exe',
    [string]$Elf = "$PSScriptRoot\..\build\debug\Demo-FreeRTOS-QEMU.elf",
    [int]$Port = 1234
)

$ErrorActionPreference = 'Stop'
$pidFile = Join-Path $PSScriptRoot 'qemu-gdb.pid'
$expectedPath = (Resolve-Path -LiteralPath $Qemu -ErrorAction Stop).Path
$processIds = [Collections.Generic.HashSet[int]]::new()

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

if (Test-Path -LiteralPath $pidFile -PathType Leaf) {
    $pidText = (Get-Content -LiteralPath $pidFile -Raw).Trim()
    $savedProcessId = 0
    if ([int]::TryParse($pidText, [ref]$savedProcessId)) {
        $savedProcess = Get-Process -Id $savedProcessId -ErrorAction SilentlyContinue
        if ($null -ne $savedProcess -and $savedProcess.Path -eq $expectedPath) {
            [void]$processIds.Add($savedProcessId)
        }
    }
}

# Port 1234 is dedicated to this launch configuration. Recover an orphaned
# server through its listener PID, while still verifying the exact executable
# before stopping anything.
foreach ($listenerProcessId in Get-ListenerProcessIds -LocalPort $Port) {
    $listenerProcess = Get-Process -Id $listenerProcessId -ErrorAction SilentlyContinue
    if ($null -eq $listenerProcess) {
        continue
    }

    if ($listenerProcess.Path -ne $expectedPath) {
        throw "Port $Port is used by '$($listenerProcess.ProcessName)' (PID $listenerProcessId), not the configured QEMU. Refusing to stop it."
    }

    [void]$processIds.Add($listenerProcessId)
}

foreach ($processId in $processIds) {
    $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
    if ($null -ne $process -and $process.Path -eq $expectedPath) {
        Stop-Process -Id $processId -Force
        $process.WaitForExit()
        Write-Output "Stopped project QEMU PID $processId."
    }
}

Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue

$deadline = [DateTime]::UtcNow.AddSeconds(5)
while ((Get-ListenerProcessIds -LocalPort $Port).Count -gt 0) {
    if ([DateTime]::UtcNow -ge $deadline) {
        throw "Port $Port is still in use after stopping the previous project QEMU."
    }
    Start-Sleep -Milliseconds 100
}

if ($processIds.Count -eq 0) {
    Write-Output 'No previous project QEMU instance is running.'
}
