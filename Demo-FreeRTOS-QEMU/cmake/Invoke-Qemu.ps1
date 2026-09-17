param(
    [Parameter(Mandatory = $true)]
    [string]$Elf,
    [switch]$DebugServer,
    [string]$Qemu = 'C:\Users\johan\zephyr-sdk-1.0.1\hosttools\qemu\qemu-system-arm.exe'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Elf -PathType Leaf)) {
    throw "ELF file not found: $Elf"
}
if (-not (Test-Path -LiteralPath $Qemu -PathType Leaf)) {
    throw "QEMU not found: $Qemu"
}

$gitMingw = 'C:\Program Files\Git\mingw64\bin'
if (Test-Path -LiteralPath $gitMingw -PathType Container) {
    $env:PATH = "$gitMingw;$env:PATH"
}

$errorLog = Join-Path (Split-Path -Parent (Resolve-Path -LiteralPath $Elf).Path) 'qemu.error.log'

$qemuArgs = @(
    '-machine', 'mps2-an385',
    '-cpu', 'cortex-m3',
    '-kernel', (Resolve-Path -LiteralPath $Elf).Path,
    '-monitor', 'none',
    '-nographic',
    '-serial', 'stdio',
    '-icount', 'shift=6,align=off,sleep=on',
    '-rtc', 'clock=vm',
    '-net', 'none'
)

if ($DebugServer) {
    $qemuArgs += @('-S', '-gdb', 'tcp::1234')
}

& $Qemu @qemuArgs 2> $errorLog
exit $LASTEXITCODE
