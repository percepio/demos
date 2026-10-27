param(
    [ValidateSet('qemu_cortex_m3', 'b_u585i-iot02a')]
    [string] $Target,

    [ValidateSet('always', 'auto')]
    [string] $Pristine = 'auto',

    [string] $CMakePath = 'cmake'
)

$ErrorActionPreference = 'Stop'
$projectDirectory = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$buildDirectory = Join-Path $projectDirectory 'build/debug'
$selectionPath = Join-Path $projectDirectory 'build/selected-target.txt'
$targets = @{
    'qemu_cortex_m3' = 'qemu_mps2_m3'
    'b_u585i-iot02a' = 'b_u585i_iot02a'
}

$cache = @{}
$cachePath = Join-Path $buildDirectory 'CMakeCache.txt'
if (Test-Path -LiteralPath $cachePath) {
    foreach ($line in Get-Content -LiteralPath $cachePath) {
        if ($line -match '^([^/#][^:]*):[^=]*=(.*)$') {
            $cache[$Matches[1]] = $Matches[2]
        }
    }
}

if (-not $Target) {
    if (Test-Path -LiteralPath $selectionPath) {
        $Target = (Get-Content -LiteralPath $selectionPath -Raw).Trim()
        if (-not $targets.ContainsKey($Target)) {
            throw "Invalid saved target '$Target'. Choose a target with Ctrl+Shift+B."
        }
    }
    elseif ($cache['DEMO_TARGET'] -eq 'b_u585i_iot02a') {
        $Target = 'b_u585i-iot02a'
    }
    else {
        $Target = 'qemu_cortex_m3'
    }
}

$cmakeTarget = $targets[$Target]
$toolchainFile = Join-Path $projectDirectory 'cmake/arm-gcc-toolchain.cmake'
$fresh = $Pristine -eq 'always' -or
    $cache['DEMO_TARGET'] -ne $cmakeTarget -or
    $cache['CMAKE_GENERATOR'] -ne 'Ninja' -or
    ($cache['CMAKE_HOME_DIRECTORY'] -replace '\\', '/') -ne ($projectDirectory -replace '\\', '/') -or
    ($cache['CMAKE_TOOLCHAIN_FILE'] -replace '\\', '/') -ne ($toolchainFile -replace '\\', '/') -or
    -not (Test-Path -LiteralPath (Join-Path $buildDirectory 'build.ninja'))
if (-not $cache['CMAKE_MAKE_PROGRAM'] -or
    -not (Test-Path -LiteralPath $cache['CMAKE_MAKE_PROGRAM'])) {
    $fresh = $true
}
$compilerInfo = Get-ChildItem -Path "$buildDirectory/CMakeFiles/*/CMakeCCompiler.cmake" -ErrorAction SilentlyContinue |
    Select-Object -First 1
if (-not $compilerInfo -or
    (Get-Content -LiteralPath $compilerInfo.FullName -Raw) -notmatch 'set\(CMAKE_C_COMPILER "([^"]+)"\)' -or
    -not (Test-Path -LiteralPath $Matches[1])) {
    $fresh = $true
}

New-Item -ItemType Directory -Path (Split-Path -Parent $selectionPath) -Force | Out-Null
# Remember even a failed build, so F5 retries the target the user selected.
[IO.File]::WriteAllText($selectionPath, $Target)
Write-Host "Building $Target (pristine=$Pristine, fresh=$fresh)."

Push-Location $projectDirectory
try {
    $configureArguments = @('--preset', 'debug', "-DDEMO_TARGET=$cmakeTarget")
    if ($fresh) { $configureArguments += '--fresh' }
    & $CMakePath @configureArguments
    if ($LASTEXITCODE -ne 0) { throw "CMake configuration failed ($LASTEXITCODE)." }

    $buildArguments = @('--build', '--preset', 'debug')
    if ($fresh) { $buildArguments += '--clean-first' }
    & $CMakePath @buildArguments
    if ($LASTEXITCODE -ne 0) { throw "CMake build failed ($LASTEXITCODE)." }

    if ($Target -eq 'qemu_cortex_m3') {
        $launchCommands = '# QEMU loads the ELF when the server starts.'
        $resetCommands = 'monitor system_reset'
    }
    else {
        $launchCommands = "monitor reset halt`nload`nmonitor reset halt"
        $resetCommands = 'monitor reset halt'
    }
    [IO.File]::WriteAllText((Join-Path $buildDirectory 'launch.gdb'), "$launchCommands`n")
    [IO.File]::WriteAllText((Join-Path $buildDirectory 'reset.gdb'), "$resetCommands`n")
}
finally {
    Pop-Location
}
