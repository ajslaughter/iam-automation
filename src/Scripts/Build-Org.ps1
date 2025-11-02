[CmdletBinding(SupportsShouldProcess = $true)]
param(
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

if (-not $ConfigPath) {
    $ConfigPath = Join-Path -Path $repoRoot -ChildPath 'config/IamLab.config.json'
}

$config = Get-LabConfig -Path $ConfigPath
$domainFqdn = Get-LabDomainFqdn

$users = @(
    @{ GivenName='John'; Surname='Stevens'; SamAccountName='jstevens'; Department='IT'; Title='Systems Administrator'; Email="jstevens@$domainFqdn"; Groups=@('GG_IT_All') },
    @{ GivenName='Priya'; Surname='Nair'; SamAccountName='pnair'; Department='Marketing'; Title='Campaign Coordinator'; Email="pnair@$domainFqdn"; Groups=@('GG_Marketing_All') },
    @{ GivenName='Logan'; Surname='Price'; SamAccountName='lprice'; Department='Finance'; Title='Staff Accountant'; Email="lprice@$domainFqdn"; Groups=@('GG_Finance_All') },
    @{ GivenName='Sofia'; Surname='Lopez'; SamAccountName='slopez'; Department='Finance'; Title='Finance Specialist'; Email="slopez@$domainFqdn"; Groups=@('GG_Finance_All') },
    @{ GivenName='Caleb'; Surname='Turner'; SamAccountName='cturner'; Department='IT'; Title='Desktop Support Technician'; Email="cturner@$domainFqdn"; Groups=@('GG_IT_All') },
    @{ GivenName='Maya'; Surname='Chen'; SamAccountName='mchen'; Department='Marketing'; Title='Digital Strategist'; Email="mchen@$domainFqdn"; Groups=@('GG_Marketing_All') }
)

$manager = @{ GivenName='Grace'; Surname='Howard'; SamAccountName='ghoward'; Department='Managers'; Title='Director of Operations'; Email="ghoward@$domainFqdn"; Groups=@('GG_IT_All','GG_Marketing_All','GG_Finance_All','GG_Managers_All') }

foreach ($entry in $users + $manager) {
    $userParams = @{
        GivenName       = $entry.GivenName
        Surname         = $entry.Surname
        SamAccountName  = $entry.SamAccountName
        OU              = $entry.Department
        TempPassword    = Get-DefaultPassword
        Department      = $entry.Department
        Title           = $entry.Title
        Email           = $entry.Email
        AddToGroups     = $entry.Groups
    }

    if ($LogPath) { $userParams['LogPath'] = $LogPath }
    if ($ResetPasswords) { $userParams['ResetPassword'] = $true }
    if ($PSBoundParameters.ContainsKey('WhatIf')) { $userParams['WhatIf'] = $true }
    if ($PSBoundParameters.ContainsKey('Confirm')) { $userParams['Confirm'] = $PSBoundParameters['Confirm'] }

    Write-Verbose "Provisioning or updating user '$($entry.SamAccountName)'."
    New-LabUser @userParams | Out-Null
}

Write-Information "Organization build tasks completed."
