[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ByName')]
param(
    [Parameter(Mandatory, ParameterSetName = 'ByName')]
    [string[]]$SamAccountName,

    [Parameter(Mandatory, ParameterSetName = 'ByCsv')]
    [string]$InputCsv,

    [Parameter()]
    [string]$ConfigPath,

    [Parameter()]
    [string]$LogPath
)

Set-StrictMode -Version Latest

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptRoot)
$moduleManifest = Join-Path -Path (Join-Path -Path $repoRoot -ChildPath 'src/Modules/IamLab') -ChildPath 'IamLab.psd1'
Import-Module $moduleManifest -Force
Ensure-Module -Name 'ActiveDirectory'

if ($PSCmdlet.ParameterSetName -eq 'ByCsv') {
    if (-not (Test-Path -LiteralPath $InputCsv)) {
        throw "CSV file not found at '$InputCsv'."
    }
    $csvRows = Import-Csv -LiteralPath $InputCsv
    if (-not $csvRows) {
        Write-Warning "No records found in '$InputCsv'."
        return
    }
    $SamAccountName = $csvRows.SamAccountName | Where-Object { $_ }
}

if (-not $SamAccountName) {
    Write-Warning 'No SamAccountName values were provided.'
    return
}

if (-not $ConfigPath) {
    $ConfigPath = Join-Path -Path $repoRoot -ChildPath 'config/IamLab.config.json'
}

$config = Get-LabConfig -Path $ConfigPath

$results = @()
foreach ($sam in $SamAccountName) {
    $entry = [pscustomobject]@{
        SamAccountName = $sam
        Disabled       = $false
        GroupsRemoved  = @()
        Notes          = ''
    }

    try {
        $user = Get-ADUser -Identity $sam -ErrorAction Stop
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        $entry.Notes = 'User not found'
        $results += $entry
        continue
    }
    catch {
        $entry.Notes = "Lookup error: $_"
        $results += $entry
        continue
    }

    $disableParams = @{ SamAccountName = $sam }
    if ($LogPath) { $disableParams['LogPath'] = $LogPath }
    if ($PSBoundParameters.ContainsKey('WhatIf')) { $disableParams['WhatIf'] = $true }
    if ($PSBoundParameters.ContainsKey('Confirm')) { $disableParams['Confirm'] = $PSBoundParameters['Confirm'] }

    try {
        Disable-LabUser @disableParams | Out-Null
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $entry.Disabled = $true
        }
    }
    catch {
        $entry.Notes = "Disable error: $_"
    }

    try {
        $memberships = Get-ADPrincipalGroupMembership -Identity $user -ErrorAction Stop | Where-Object { $_.Name -like 'GG_*' }
    }
    catch {
        $entry.Notes = "Group lookup error: $_"
        $results += $entry
        continue
    }

    foreach ($group in $memberships) {
        $removeParams = @{
            SamAccountName = $sam
            Group          = $group.DistinguishedName
        }
        if ($LogPath) { $removeParams['LogPath'] = $LogPath }
        if ($PSBoundParameters.ContainsKey('WhatIf')) { $removeParams['WhatIf'] = $true }
        if ($PSBoundParameters.ContainsKey('Confirm')) { $removeParams['Confirm'] = $PSBoundParameters['Confirm'] }

        try {
            Remove-LabUserFromGroup @removeParams | Out-Null
            if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
                $entry.GroupsRemoved += $group.Name
            }
        }
        catch {
            $entry.Notes = "Group removal error: $_"
        }
    }

    if ($PSBoundParameters.ContainsKey('WhatIf')) {
        if ($entry.Notes) {
            $entry.Notes = "$($entry.Notes); simulated changes"
        }
        else {
            $entry.Notes = 'Simulated changes'
        }
    }

    $results += $entry
}

$results = $results | ForEach-Object {
    [pscustomobject]@{
        SamAccountName = $_.SamAccountName
        Disabled       = $_.Disabled
        GroupsRemoved  = ($_.GroupsRemoved -join ';')
        Notes          = $_.Notes
    }
}

if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
    $logRoot = if ($LogPath) { $LogPath } else { $config.LoggingRoot }
    $dateSegment = Get-Date -Format 'yyyy-MM-dd'
    $logDir = Join-Path -Path $logRoot -ChildPath $dateSegment
    if (-not (Test-Path -LiteralPath $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    $reportPath = Join-Path -Path $logDir -ChildPath 'deprovision.csv'
    $results | Export-Csv -LiteralPath $reportPath -NoTypeInformation
    Write-LabLog -Level 'INFO' -Message "Deprovision report written to '$reportPath'." -LogPath $LogPath
}
else {
    Write-Information 'WhatIf specified. Report not written to disk.'
}

return $results
