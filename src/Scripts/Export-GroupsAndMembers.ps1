[CmdletBinding(SupportsShouldProcess = $true)]
param(
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

if (-not $ConfigPath) {
    $ConfigPath = Join-Path -Path $repoRoot -ChildPath 'config/IamLab.config.json'
}

Get-LabConfig -Path $ConfigPath | Out-Null

Write-Verbose 'Retrieving GG_* groups from Active Directory.'
$groups = Get-ADGroup -Filter "Name -like 'GG_*'" -ErrorAction Stop

$rows = @()
foreach ($group in $groups) {
    try {
        $members = Get-ADGroupMember -Identity $group -Recursive -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to enumerate members for '$($group.Name)'. $_"
        $members = @()
    }

    if (-not $members) {
        $rows += [pscustomobject]@{
            GroupName      = $group.Name
            GroupDN        = $group.DistinguishedName
            MemberType     = ''
            MemberName     = ''
            MemberSam      = ''
        }
        continue
    }

    foreach ($member in $members) {
        $rows += [pscustomobject]@{
            GroupName      = $group.Name
            GroupDN        = $group.DistinguishedName
            MemberType     = $member.objectClass
            MemberName     = $member.Name
            MemberSam      = $member.SamAccountName
        }
    }
}

if (-not $rows) {
    Write-Warning 'No GG_* groups were found.'
    return
}

if ($PSCmdlet.ShouldProcess('File system', 'Export GG_* group membership report')) {
    $logRoot = if ($LogPath) { $LogPath } else { (Get-LabConfig).LoggingRoot }
    $dateSegment = Get-Date -Format 'yyyy-MM-dd'
    $logDir = Join-Path -Path $logRoot -ChildPath $dateSegment
    if (-not (Test-Path -LiteralPath $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    $reportPath = Join-Path -Path $logDir -ChildPath 'groups.csv'
    $rows | Export-Csv -LiteralPath $reportPath -NoTypeInformation
    Write-LabLog -Level 'INFO' -Message "Group membership report written to '$reportPath'." -LogPath $LogPath
    Write-Information "Exported group membership report to '$reportPath'."
}
