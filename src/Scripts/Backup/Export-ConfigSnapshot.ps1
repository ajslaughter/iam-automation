[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputRoot
)

#requires -Modules ActiveDirectory, GroupPolicy

$repoRoot = Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..')
if (-not $OutputRoot) {
    $OutputRoot = Join-Path -Path $repoRoot -ChildPath 'backups'
}

$timestamp = Get-Date -Format 'yyyyMMddHHmmss'
$targetPath = Join-Path -Path $OutputRoot -ChildPath $timestamp
if (-not (Test-Path -Path $targetPath)) {
    New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
}

Write-Verbose "Exporting configuration snapshot to '$targetPath'."

$ous = Get-ADOrganizationalUnit -Filter * -Properties DistinguishedName, Name
$groups = Get-ADGroup -Filter * -Properties Name, ManagedBy, Description, GroupScope, GroupCategory
$users = Get-ADUser -Filter * -Properties SamAccountName, DisplayName, Enabled, Department, Title, EmailAddress
$ouWithLinks = Get-ADOrganizationalUnit -Filter * -Properties DistinguishedName, LinkedGroupPolicyObjects

$snapshot = [ordered]@{
    GeneratedOn              = Get-Date
    OrganizationalUnits      = $ous | Select-Object Name, DistinguishedName
    Groups                   = $groups | Select-Object Name, GroupScope, GroupCategory, ManagedBy, Description
    Users                    = $users | Select-Object SamAccountName, DisplayName, Enabled, Department, Title, EmailAddress
    GroupPolicyAssignments   = $ouWithLinks | Where-Object { $_.LinkedGroupPolicyObjects } | ForEach-Object {
        [pscustomobject]@{
            TargetOU = $_.DistinguishedName
            Links    = $_.LinkedGroupPolicyObjects
        }
    }
}

$snapshot | ConvertTo-Json -Depth 6 | Out-File -FilePath (Join-Path -Path $targetPath -ChildPath 'config-snapshot.json') -Encoding UTF8

Write-Output $targetPath
