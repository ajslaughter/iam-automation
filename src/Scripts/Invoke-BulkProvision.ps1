[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter()]
    [string]$ConfigPath,

    [Parameter()]
    [string]$LogPath,

    [Parameter()]
    [switch]$ResetPasswords
)

Set-StrictMode -Version Latest

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptRoot)
$moduleManifest = Join-Path -Path (Join-Path -Path $repoRoot -ChildPath 'src/Modules/IamLab') -ChildPath 'IamLab.psd1'
Import-Module $moduleManifest -Force
Ensure-Module -Name 'ActiveDirectory'

if (-not (Test-Path -LiteralPath $Path)) {
    throw "CSV file not found at '$Path'."
}

if (-not $ConfigPath) {
    $ConfigPath = Join-Path -Path $repoRoot -ChildPath 'config/IamLab.config.json'
}

Get-LabConfig -Path $ConfigPath | Out-Null

$requiredHeaders = 'SamAccountName','GivenName','Surname','OU','Email','Title','Department','AddToGroups'
$headerLine = (Get-Content -LiteralPath $Path -First 1)
$headers = $headerLine -split ',' | ForEach-Object { $_.Trim() }
$missing = $requiredHeaders | Where-Object { $headers -notcontains $_ }
if ($missing) {
    throw "CSV file is missing required headers: $($missing -join ', ')."
}

$rows = Import-Csv -LiteralPath $Path
if (-not $rows) {
    Write-Warning "No records found in '$Path'."
    return
}

$results = @()

foreach ($row in $rows) {
    if (-not $row.SamAccountName) {
        Write-Warning "Skipping row with missing SamAccountName."
        $results += [pscustomobject]@{ SamAccountName = '(missing)'; Action = 'Skipped - Missing SamAccountName' }
        continue
    }

    $exists = $false
    try {
        Get-ADUser -Identity $row.SamAccountName -ErrorAction Stop | Out-Null
        $exists = $true
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        $exists = $false
    }
    catch {
        $message = "Failed to query user '$($row.SamAccountName)'. $_"
        Write-LabLog -Level 'ERROR' -Message $message -LogPath $LogPath
        $results += [pscustomobject]@{ SamAccountName = $row.SamAccountName; Action = 'Error' }
        continue
    }

    $groups = @()
    if ($row.AddToGroups) {
        $groups = $row.AddToGroups -split '[;,]' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    }

    $userParams = @{
        GivenName      = $row.GivenName
        Surname        = $row.Surname
        SamAccountName = $row.SamAccountName
        OU             = $row.OU
        TempPassword   = Get-DefaultPassword
        Email          = $row.Email
        Title          = $row.Title
        Department     = $row.Department
        AddToGroups    = $groups
    }

    if ($LogPath) { $userParams['LogPath'] = $LogPath }
    if ($ResetPasswords) { $userParams['ResetPassword'] = $true }
    if ($PSBoundParameters.ContainsKey('WhatIf')) { $userParams['WhatIf'] = $true }
    if ($PSBoundParameters.ContainsKey('Confirm')) { $userParams['Confirm'] = $PSBoundParameters['Confirm'] }

    try {
        New-LabUser @userParams | Out-Null
        $action = if ($exists) { 'Updated' } else { 'Created' }
        if ($PSBoundParameters.ContainsKey('WhatIf')) { $action = "WhatIf - $action" }
        $results += [pscustomobject]@{ SamAccountName = $row.SamAccountName; Action = $action }
    }
    catch {
        $message = "Failed to process user '$($row.SamAccountName)'. $_"
        Write-LabLog -Level 'ERROR' -Message $message -LogPath $LogPath
        Write-Error $message
        $results += [pscustomobject]@{ SamAccountName = $row.SamAccountName; Action = 'Error' }
    }
}

$summary = $results | Group-Object -Property Action | Select-Object Name, @{Name='Count';Expression={$_.Count}}
Write-Information "Bulk provision summary:"
$summary | Format-Table -AutoSize | Out-String | Write-Information

return $results
