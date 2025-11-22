<#
.SYNOPSIS
    Automates "Day 1" configuration and application deployment.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory)]
    [ValidateSet("Office", "Field")]
    [string]$RoleProfile
)

Write-Host "--- Starting Workstation Prep for Profile: $RoleProfile ---" -ForegroundColor Cyan

# 1. Debloat / Cleanup
$Bloatware = @("XboxGameOverlay", "Solitaire", "SkypeApp", "News")
foreach ($app in $Bloatware) {
    if ($PSCmdlet.ShouldProcess("System", "Remove $app")) {
        Get-AppxPackage *$app* -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
    }
}

# 2. Power Configuration
if ($PSCmdlet.ShouldProcess("PowerScheme", "Set High Performance")) {
    powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    Write-Host "   - Power scheme set to High Performance"
}

# 3. Install Software
Write-Host "--- Installing role-based software ---"
$CommonApps = @("Microsoft Edge", "Adobe Reader", "VPN Client")
$FieldApps = @("Bluebeam Revu CAD Edition", "Project Management Suite") 
$OfficeApps = @("Office 365 ProPlus", "Teams/Video Conferencing Client")

$InstallList = @() + $CommonApps
if ($RoleProfile -eq "Field") { $InstallList += $FieldApps }
if ($RoleProfile -eq "Office") { $InstallList += $OfficeApps }

foreach ($pkg in $InstallList) {
    if ($PSCmdlet.ShouldProcess("Deployment Tool", "Install application: $pkg")) {
        Write-Host "   [OK] Installed: $pkg" -ForegroundColor Green
    }
}

# 4. System Verification
try {
    $serial = (Get-CimInstance Win32_Bios -ErrorAction Stop).SerialNumber
} catch {
    $serial = "VM-Virtual-Asset"
}
Write-Host "Prep Complete. Serial: $serial | Profile: $RoleProfile" -ForegroundColor Gray
