<#
.SYNOPSIS
Attributes linked Flash/ROM and RAM to object-file groups in a GNU ld map.

.DESCRIPTION
The default groups recognize TraceRecorder and DFM object files in Zephyr's
Percepio library. The script has no external dependencies.

Flash/ROM includes executable/read-only bytes plus the load image for
initialized RAM. RAM (init) is therefore intentionally counted in both the
Flash/ROM and RAM totals. Alignment padding and indirectly enabled libraries
cannot be attributed to an object group from one map file and are excluded.

Thread-local storage (TLS) is reported per thread rather than as ordinary
static RAM. Zephyr typically reserves each thread's TLS block inside that
thread's stack, so TLS reduces usable stack space without appearing as a
separate allocation in the image's RAM address range.

.EXAMPLE
./tools/analyze_module_memory.ps1

.EXAMPLE
./tools/analyze_module_memory.ps1 build/zephyr/zephyr.map -Details

.EXAMPLE
./tools/analyze_module_memory.ps1 app.map -AsJson

.EXAMPLE
./tools/analyze_module_memory.ps1 app.map -NoDefaultGroups `
    -Group 'MyModule=libmymodule\.a\('
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string] $MapFile = 'build/zephyr/zephyr.map',

    [Parameter()]
    [string[]] $Group = @(),

    [Parameter()]
    [switch] $NoDefaultGroups,

    [Parameter()]
    [switch] $Details,

    [Parameter()]
    [switch] $AsJson
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$hexPattern = '0x[0-9A-Fa-f]+'
$memoryRegionPattern = "^(?<name>\S+)\s+(?<origin>$hexPattern)\s+(?<length>$hexPattern)(?:\s+(?<attributes>\S+))?\s*$"
$outputSectionPattern = "^(?<name>\S+)\s+(?<vma>$hexPattern)\s+(?<size>$hexPattern)(?:\s+load address\s+(?<lma>$hexPattern))?(?:\s|$)"
$inputSectionPattern = "^\s+(?:(?<section>\S+)\s+)?(?<vma>$hexPattern)\s+(?<size>$hexPattern)\s+(?<object>.+?(?:\.obj|\.o)(?:\)|$))\s*$"
$nonAllocOutputPattern = '^(?:\.debug|\.zdebug|\.stab|\.comment$|\.(?:ARM|riscv)\.attributes$|\.symtab|\.strtab|\.shstrtab|\.gdb_index|\.rel(?:a)?(?:\.|$))'

$groups = [ordered] @{}
if (-not $NoDefaultGroups) {
    $groups.TraceRecorder = 'percepio[^()]*\.a\(trc[^()/\\]*\.(?:c|cc|cpp|s)\.(?:obj|o)\)$'
    $groups.DFM = 'percepio[^()]*\.a\(dfm[^()/\\]*\.(?:c|cc|cpp|s)\.(?:obj|o)\)$'
}

foreach ($groupSpec in $Group) {
    $equalsIndex = $groupSpec.IndexOf('=')
    if ($equalsIndex -le 0 -or $equalsIndex -eq ($groupSpec.Length - 1)) {
        throw "Group must use NAME=REGEX syntax: $groupSpec"
    }
    $name = $groupSpec.Substring(0, $equalsIndex)
    $pattern = $groupSpec.Substring($equalsIndex + 1)
    try {
        [void] [regex]::new($pattern)
    }
    catch {
        throw "Invalid regex for group '$name': $($_.Exception.Message)"
    }
    $groups[$name] = $pattern
}

if ($groups.Count -eq 0) {
    throw 'No groups configured. Remove -NoDefaultGroups or add at least one -Group NAME=REGEX.'
}

$resolvedMapFile = (Resolve-Path -LiteralPath $MapFile).Path
$regions = [System.Collections.Generic.List[object]]::new()
$contributions = [System.Collections.Generic.List[object]]::new()
$inMemoryConfig = $false
$inLinkMap = $false
$currentOutput = $null
$pendingInputSection = ''

foreach ($line in [System.IO.File]::ReadLines($resolvedMapFile)) {
    if ($line -eq 'Memory Configuration') {
        $inMemoryConfig = $true
        continue
    }
    if ($line -eq 'Linker script and memory map') {
        $inMemoryConfig = $false
        $inLinkMap = $true
        continue
    }

    if ($inMemoryConfig) {
        if ($line -match $memoryRegionPattern -and $Matches.name -notin @('Name', '*default*')) {
            $regions.Add([pscustomobject] @{
                Name       = $Matches.name
                Origin     = [Convert]::ToUInt64($Matches.origin.Substring(2), 16)
                Length     = [Convert]::ToUInt64($Matches.length.Substring(2), 16)
                Attributes = $Matches['attributes']
            })
        }
        continue
    }

    if (-not $inLinkMap) {
        continue
    }
    if ($line.StartsWith('OUTPUT(')) {
        break
    }
    if ($line -eq '/DISCARD/') {
        $currentOutput = $null
        $pendingInputSection = ''
        continue
    }

    # GNU ld output-section headers start in column zero. Input sections and
    # their continuation lines are indented.
    if ($line.Length -gt 0 -and -not [char]::IsWhiteSpace($line[0])) {
        if ($line -match $outputSectionPattern) {
            $lma = $null
            if ($Matches['lma']) {
                $lma = [Convert]::ToUInt64($Matches['lma'].Substring(2), 16)
            }
            $currentOutput = [pscustomobject] @{
                Name = $Matches.name
                Vma  = [Convert]::ToUInt64($Matches.vma.Substring(2), 16)
                Size = [Convert]::ToUInt64($Matches.size.Substring(2), 16)
                Lma  = $lma
            }
        }
        else {
            $currentOutput = $null
        }
        $pendingInputSection = ''
        continue
    }

    if ($null -eq $currentOutput) {
        continue
    }

    if ($line -match $inputSectionPattern) {
        $objectFile = $Matches.object
        $size = [Convert]::ToUInt64($Matches.size.Substring(2), 16)
        $address = [Convert]::ToUInt64($Matches.vma.Substring(2), 16)
        $inputSection = $Matches['section']
        if (-not $inputSection) {
            $inputSection = $pendingInputSection
        }
        $pendingInputSection = ''
        if ($size -eq 0) {
            continue
        }
        # Debug information and other ELF metadata commonly use VMA zero, which
        # can overlap a real flash region without being loaded onto the target.
        if ($currentOutput.Name -match $nonAllocOutputPattern) {
            continue
        }

        if ($currentOutput.Name -in @('tdata', '.tdata')) {
            $storage = 'TlsInit'
        }
        elseif ($currentOutput.Name -in @('tbss', '.tbss')) {
            $storage = 'TlsNoLoad'
        }
        else {
            $region = $null
            foreach ($candidate in $regions) {
                if ($address -ge $candidate.Origin -and $address -lt ($candidate.Origin + $candidate.Length)) {
                    $region = $candidate
                    break
                }
            }
            if ($null -eq $region) {
                continue
            }

            if ($region.Attributes -notmatch 'w') {
                $storage = 'FlashResident'
            }
            elseif ($null -ne $currentOutput.Lma -and $currentOutput.Lma -ne $currentOutput.Vma) {
                $storage = 'RamInit'
            }
            else {
                $storage = 'RamNoLoad'
            }
        }

        foreach ($entry in $groups.GetEnumerator()) {
            if ($objectFile -match $entry.Value) {
                $contributions.Add([pscustomobject] @{
                    Group         = $entry.Key
                    ObjectFile    = $objectFile
                    InputSection  = $inputSection
                    OutputSection = $currentOutput.Name
                    Size          = $size
                    Storage       = $storage
                })
            }
        }
        continue
    }

    $stripped = $line.Trim()
    if ($stripped.StartsWith('.') -and -not $stripped.Contains(' ')) {
        $pendingInputSection = $stripped
    }
}

if ($regions.Count -eq 0) {
    throw 'No memory regions found. Is this a GNU ld map file?'
}

function New-MemoryTotals {
    [ordered] @{
        FlashResident = [uint64] 0
        RamInit       = [uint64] 0
        RamNoLoad     = [uint64] 0
        TlsInit       = [uint64] 0
        TlsNoLoad     = [uint64] 0
    }
}

function Complete-MemoryTotals([System.Collections.IDictionary] $Totals) {
    [ordered] @{
        FlashRom      = [uint64] ($Totals.FlashResident + $Totals.RamInit + $Totals.TlsInit)
        FlashResident = [uint64] $Totals.FlashResident
        RamTotal      = [uint64] ($Totals.RamInit + $Totals.RamNoLoad)
        RamInit       = [uint64] $Totals.RamInit
        RamNoLoad     = [uint64] $Totals.RamNoLoad
        TlsPerThread  = [uint64] ($Totals.TlsInit + $Totals.TlsNoLoad)
        TlsInit       = [uint64] $Totals.TlsInit
        TlsNoLoad     = [uint64] $Totals.TlsNoLoad
    }
}

$rawTotals = [ordered] @{}
foreach ($name in $groups.Keys) {
    $rawTotals[$name] = New-MemoryTotals
}
foreach ($item in $contributions) {
    $rawTotals[$item.Group][$item.Storage] += $item.Size
}

$rows = [System.Collections.Generic.List[object]]::new()
foreach ($name in $groups.Keys) {
    $totals = Complete-MemoryTotals $rawTotals[$name]
    $rows.Add([pscustomobject] @{
        Group         = $name
        FlashRom      = $totals.FlashRom
        FlashResident = $totals.FlashResident
        RamTotal      = $totals.RamTotal
        RamInit       = $totals.RamInit
        RamNoLoad     = $totals.RamNoLoad
        TlsPerThread  = $totals.TlsPerThread
        TlsInit       = $totals.TlsInit
        TlsNoLoad     = $totals.TlsNoLoad
    })
}

if ($rows.Count -gt 1) {
    $rows.Add([pscustomobject] @{
        Group         = 'Combined'
        FlashRom      = [uint64] (($rows | Measure-Object -Property FlashRom -Sum).Sum)
        FlashResident = [uint64] (($rows | Measure-Object -Property FlashResident -Sum).Sum)
        RamTotal      = [uint64] (($rows | Measure-Object -Property RamTotal -Sum).Sum)
        RamInit       = [uint64] (($rows | Measure-Object -Property RamInit -Sum).Sum)
        RamNoLoad     = [uint64] (($rows | Measure-Object -Property RamNoLoad -Sum).Sum)
        TlsPerThread  = [uint64] (($rows | Measure-Object -Property TlsPerThread -Sum).Sum)
        TlsInit       = [uint64] (($rows | Measure-Object -Property TlsInit -Sum).Sum)
        TlsNoLoad     = [uint64] (($rows | Measure-Object -Property TlsNoLoad -Sum).Sum)
    })
}

if ($AsJson) {
    $groupResults = [ordered] @{}
    foreach ($row in $rows | Where-Object Group -ne 'Combined') {
        $groupResults[$row.Group] = [ordered] @{
            flash_rom      = $row.FlashRom
            flash_resident = $row.FlashResident
            ram_total      = $row.RamTotal
            ram_init       = $row.RamInit
            ram_noload     = $row.RamNoLoad
            tls_per_thread = $row.TlsPerThread
            tls_init       = $row.TlsInit
            tls_noload     = $row.TlsNoLoad
        }
    }
    $result = [ordered] @{
        map_file       = $resolvedMapFile
        memory_regions = $regions
        groups         = $groupResults
    }
    if ($rows.Count -gt 1) {
        $combinedRow = $rows[$rows.Count - 1]
        $result.combined = [ordered] @{
            flash_rom      = $combinedRow.FlashRom
            flash_resident = $combinedRow.FlashResident
            ram_total      = $combinedRow.RamTotal
            ram_init       = $combinedRow.RamInit
            ram_noload     = $combinedRow.RamNoLoad
            tls_per_thread = $combinedRow.TlsPerThread
            tls_init       = $combinedRow.TlsInit
            tls_noload     = $combinedRow.TlsNoLoad
        }
    }
    $result | ConvertTo-Json -Depth 5
    exit 0
}

Write-Output "Map: $resolvedMapFile"
Write-Output 'All sizes are bytes. Direct linked object contributions only.'
Write-Output ''
Write-Output ('{0,-16} {1,12} {2,12} {3,12} {4,16} {5,12}' -f 'Group', 'Flash/ROM', 'RAM total', 'RAM init', 'RAM zero/noinit', 'TLS/thread')
Write-Output ('{0,-16} {1,12} {2,12} {3,12} {4,16} {5,12}' -f ('-' * 16), ('-' * 12), ('-' * 12), ('-' * 12), ('-' * 16), ('-' * 12))
foreach ($row in $rows) {
    Write-Output ('{0,-16} {1,12:N0} {2,12:N0} {3,12:N0} {4,16:N0} {5,12:N0}' -f $row.Group, $row.FlashRom, $row.RamTotal, $row.RamInit, $row.RamNoLoad, $row.TlsPerThread)
}

if ($Details) {
    foreach ($name in $groups.Keys) {
        Write-Output ''
        Write-Output "$name by object:"
        $objectRows = [System.Collections.Generic.List[object]]::new()
        foreach ($objectGroup in ($contributions | Where-Object Group -eq $name | Group-Object ObjectFile)) {
            $objectTotals = New-MemoryTotals
            foreach ($item in $objectGroup.Group) {
                $objectTotals[$item.Storage] += $item.Size
            }
            $complete = Complete-MemoryTotals $objectTotals
            $objectRows.Add([pscustomobject] @{
                Object    = $objectGroup.Name
                FlashRom  = $complete.FlashRom
                RamTotal  = $complete.RamTotal
                RamInit   = $complete.RamInit
                RamNoLoad = $complete.RamNoLoad
                TlsPerThread = $complete.TlsPerThread
                SortSize  = $complete.FlashRom + $complete.RamTotal
            })
        }
        Write-Output ('{0,-52} {1,12} {2,12} {3,12} {4,16} {5,12}' -f 'Object', 'Flash/ROM', 'RAM total', 'RAM init', 'RAM zero/noinit', 'TLS/thread')
        Write-Output ('{0,-52} {1,12} {2,12} {3,12} {4,16} {5,12}' -f ('-' * 52), ('-' * 12), ('-' * 12), ('-' * 12), ('-' * 16), ('-' * 12))
        foreach ($objectRow in ($objectRows | Sort-Object SortSize -Descending)) {
            $shortObject = $objectRow.Object -replace '^.*\.a\(', ''
            Write-Output ('{0,-52} {1,12:N0} {2,12:N0} {3,12:N0} {4,16:N0} {5,12:N0}' -f $shortObject, $objectRow.FlashRom, $objectRow.RamTotal, $objectRow.RamInit, $objectRow.RamNoLoad, $objectRow.TlsPerThread)
        }
    }
}

Write-Output ''
Write-Output 'Notes:'
Write-Output '  - Flash/ROM includes the load image of initialized RAM.'
Write-Output '  - RAM total includes initialized, zero-initialized, and noinit data.'
Write-Output '  - TLS/thread is additional thread-local data, normally reserved inside each Zephyr thread stack.'
Write-Output '  - Linker padding and indirectly enabled dependencies are excluded.'
