[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [string]$ConfigPath,

    [Parameter()]
    [string]$LogPath
)

Set-StrictMode -Version Latest

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$repoRoot = Split-Path -Parent $repoRoot
$moduleManifest = Join-Path -Path (Join-Path -Path $repoRoot -ChildPath 'src/Modules/IamLab') -ChildPath 'IamLab.psd1'
Import-Module $moduleManifest -Force

if (-not $ConfigPath) {
    $ConfigPath = Join-Path -Path $repoRoot -ChildPath 'config/IamLab.config.json'
}

$config = Get-LabConfig -Path $ConfigPath

$commonParams = @{}
if ($LogPath) { $commonParams['LogPath'] = $LogPath }
if ($PSBoundParameters.ContainsKey('WhatIf')) { $commonParams['WhatIf'] = $true }
if ($PSBoundParameters.ContainsKey('Confirm')) { $commonParams['Confirm'] = $PSBoundParameters['Confirm'] }

$testParams = $commonParams.Clone()
if ($testParams.ContainsKey('WhatIf')) { $testParams.Remove('WhatIf') }
Test-LabAdAvailable @testParams | Out-Null

if ($config.CompanyOUDN -notmatch '^OU=([^,]+),(.*)$') {
    throw "CompanyOUDN '$($config.CompanyOUDN)' is not a valid distinguished name."
}

$companyName = $Matches[1]
$companyPath = $Matches[2]
New-LabOU @commonParams -Name $companyName -Path $companyPath | Out-Null

foreach ($department in $config.Departments) {
    Write-Verbose "Ensuring organizational unit for department '$department'."
    New-LabOU @commonParams -Name $department -Path $config.CompanyOUDN | Out-Null

    $groupName = "GG_${department}_All"
    $description = "All members of the $department department"
    New-LabSecurityGroup @commonParams -Name $groupName -OU $department -Scope 'Global' -Description $description | Out-Null
}

Write-Information "Environment initialization tasks completed."
