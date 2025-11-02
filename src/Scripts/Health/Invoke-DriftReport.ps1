[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [string]$ConfigPath,

    [Parameter()]
    [string]$OutputPath
)

#requires -Modules ActiveDirectory

$repoRoot = Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..')
if (-not $ConfigPath) {
    $ConfigPath = Join-Path -Path $repoRoot -ChildPath 'config/desired-state.json'
}

if (-not (Test-Path -Path $ConfigPath)) {
    throw "Desired state configuration file '$ConfigPath' was not found."
}

if (-not $OutputPath) {
    $OutputPath = Join-Path -Path $repoRoot -ChildPath 'backups/drift-report.csv'
}

$desiredState = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
$results = @()

function Add-Drift {
    param(
        [ref]$Collection,
        [string]$ItemType,
        [string]$Identifier,
        [string]$Issue,
        [string]$Details
    )

    $Collection.Value += [pscustomobject]@{
        ItemType   = $ItemType
        Identifier = $Identifier
        Issue      = $Issue
        Details    = $Details
    }
}

$desiredOus = @()
if ($desiredState.OrganizationalUnits) {
    foreach ($ou in $desiredState.OrganizationalUnits) {
        if ($ou -is [string]) {
            $desiredOus += $ou
        } elseif ($ou.DistinguishedName) {
            $desiredOus += $ou.DistinguishedName
        }
    }
}

foreach ($ouDn in $desiredOus) {
    try {
        $null = Get-ADOrganizationalUnit -Identity $ouDn -ErrorAction Stop
    } catch {
        Add-Drift -Collection ([ref]$results) -ItemType 'OU' -Identifier $ouDn -Issue 'Missing' -Details 'Organizational Unit not found.'
    }
}

$parentLookup = @{}
foreach ($ouDn in $desiredOus) {
    if ($ouDn -match '^[^,]+,(.+)$') {
        $parent = $Matches[1]
        if (-not $parentLookup.ContainsKey($parent)) {
            $parentLookup[$parent] = @()
        }
        $parentLookup[$parent] += $ouDn
    }
}

foreach ($parent in $parentLookup.Keys) {
    try {
        $children = Get-ADOrganizationalUnit -Filter * -SearchBase $parent -SearchScope OneLevel -ErrorAction Stop
        foreach ($child in $children) {
            if ($desiredOus -notcontains $child.DistinguishedName) {
                Add-Drift -Collection ([ref]$results) -ItemType 'OU' -Identifier $child.DistinguishedName -Issue 'Extra' -Details "Not defined in desired state under $parent."
            }
        }
    } catch {
        Add-Drift -Collection ([ref]$results) -ItemType 'OU' -Identifier $parent -Issue 'Changed' -Details "Unable to enumerate child OUs: $($_.Exception.Message)"
    }
}

$desiredGroups = @()
if ($desiredState.Groups) {
    foreach ($group in $desiredState.Groups) {
        if ($group -is [string]) {
            $desiredGroups += [pscustomobject]@{ Name = $group; Members = @(); Container = $null }
        } else {
            $desiredGroups += [pscustomobject]@{
                Name      = $group.Name
                Members   = @($group.Members)
                Container = $group.Container
            }
        }
    }
}

$containerMap = @{}
foreach ($group in $desiredGroups) {
    if (-not $group.Name) { continue }
    try {
        $adGroup = Get-ADGroup -Identity $group.Name -ErrorAction Stop
    } catch {
        Add-Drift -Collection ([ref]$results) -ItemType 'Group' -Identifier $group.Name -Issue 'Missing' -Details 'Group not found.'
        if ($group.Container) {
            if (-not $containerMap.ContainsKey($group.Container)) { $containerMap[$group.Container] = @() }
            $containerMap[$group.Container] += $group.Name
        }
        continue
    }

    if ($group.Container) {
        if (-not $containerMap.ContainsKey($group.Container)) { $containerMap[$group.Container] = @() }
        $containerMap[$group.Container] += $group.Name
    }

    if ($group.Members -and $group.Members.Count -gt 0) {
        try {
            $members = Get-ADGroupMember -Identity $adGroup.DistinguishedName -Recursive:$false -ErrorAction Stop | Select-Object -ExpandProperty SamAccountName
        } catch {
            Add-Drift -Collection ([ref]$results) -ItemType 'Group' -Identifier $group.Name -Issue 'Changed' -Details "Unable to enumerate members: $($_.Exception.Message)"
            continue
        }

        $expected = $group.Members | Where-Object { $_ }
        $missingMembers = $expected | Where-Object { $members -notcontains $_ }
        $extraMembers = $members | Where-Object { $expected -notcontains $_ }

        if ($missingMembers -or $extraMembers) {
            $details = @()
            if ($missingMembers) { $details += 'Missing members: ' + ($missingMembers -join ', ') }
            if ($extraMembers) { $details += 'Extra members: ' + ($extraMembers -join ', ') }
            Add-Drift -Collection ([ref]$results) -ItemType 'Group' -Identifier $group.Name -Issue 'Changed' -Details ($details -join ' | ')
        }
    }
}

foreach ($container in $containerMap.Keys) {
    try {
        $actualGroups = Get-ADGroup -Filter * -SearchBase $container -SearchScope OneLevel -ErrorAction Stop
        foreach ($actualGroup in $actualGroups) {
            if ($containerMap[$container] -notcontains $actualGroup.Name) {
                Add-Drift -Collection ([ref]$results) -ItemType 'Group' -Identifier $actualGroup.Name -Issue 'Extra' -Details "Located in $container but not defined in desired state."
            }
        }
    } catch {
        Add-Drift -Collection ([ref]$results) -ItemType 'Group' -Identifier $container -Issue 'Changed' -Details "Unable to enumerate groups: $($_.Exception.Message)"
    }
}

if ($PSCmdlet.ShouldProcess($OutputPath, 'Write drift report')) {
    if (-not (Test-Path -Path (Split-Path -Path $OutputPath -Parent))) {
        New-Item -ItemType Directory -Path (Split-Path -Path $OutputPath -Parent) -Force | Out-Null
    }
    $results | Export-Csv -Path $OutputPath -NoTypeInformation
}

$results
