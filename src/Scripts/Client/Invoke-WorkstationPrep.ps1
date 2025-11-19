<#
.SYNOPSIS
    Automates "Day 1" configuration and application deployment for a new endpoint.
.DESCRIPTION
    Standardizes a workstation for an Adolfson & Peterson employee. Mimics an SCCM Task Sequence.
    - Removes bloatware.
    - Sets power management.
    - Installs role-based software (Field or Office).
.PARAMETER RoleProfile
    The standard workstation profile to apply: 'Office' or 'Field'.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory)]
    [ValidateSet("Office", "Field")]
    [string]$RoleProfile
)

Write-Host "🚀 Starting Workstation Prep for Profile: $RoleProfile" -ForegroundColor Cyan

# 1. Debloat / Cleanup
$Bloatware = @("XboxGameOverlay", "Solitaire", "SkypeApp", "News")
Write-Verbose "Removing Windows bloatware..."
foreach ($app in $Bloatware) {
    if ($PSCmdlet.ShouldProcess("System", "Remove $app")) {
        Get-AppxPackage *$app* | Remove-AppxPackage -ErrorAction SilentlyContinue
    }
}

# 2. Power Configuration (Optimizing for performance/uptime)
if ($PSCmdlet.ShouldProcess("PowerScheme", "Set High Performance")) {
    # GUID for High Performance: 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    Write-Host "   - Power scheme set to High Performance"
}

# 3. Install Software (Simulated Deployment via SCCM/Intune)
Write-Host "📦 Starting role-based software installation..."
$CommonApps = @("Microsoft Edge", "Adobe Reader", "VPN Client")
$FieldApps = @("Bluebeam Revu (CAD)", "Project Management Suite") # Construction specific tools
$OfficeApps = @("Office 365 ProPlus", "Teams/Video Conferencing Client")

$InstallList = $CommonApps
if ($RoleProfile -eq "Field") { $InstallList += $FieldApps }
if ($RoleProfile -eq "Office") { $InstallList += $OfficeApps }

foreach ($pkg in $InstallList) {
    if ($PSCmdlet.ShouldProcess("Deployment Tool", "Install application: $pkg")) {
        # Mocking deployment: In production, this would call Install-Package or trigger SCCM client
        Write-Host "   ✅ Installed: $pkg" -ForegroundColor Green
    }
}

# 4. System Verification
$serial = (Get-CimInstance Win32_Bios).SerialNumber
Write-Host "📝 Prep Complete. Serial: $serial | Profile: $RoleProfile" -ForegroundColor Gray
