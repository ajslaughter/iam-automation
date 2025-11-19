<#
.SYNOPSIS
    Displays the daily safety briefing and verifies IT safety compliance (IIF Culture).
.DESCRIPTION
    Aligns with Adolfson & Peterson's IIF (Incident and Injury Free) culture.
    This script is designed to be run by IT staff upon arriving at a job site
    to review common IT-related hazards (cabling, electrical) and log their presence.
.PARAMETER JobSiteID
    The unique identifier for the construction site (e.g., 'BismarckDC-001').
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory)]
    [string]$JobSiteID,

    [Parameter()]
    [switch]$ForceSkipAcknowledgement
)

$SafetyTips = @(
    "IIF Reminder: Ensure all temporary network cabling is taped down to prevent trip hazards.",
    "IIF Reminder: Verify ladder safety before mounting wireless access points (3 points of contact).",
    "IIF Reminder: Hydrate! Field sites can experience extreme heat or cold.",
    "IIF Reminder: Secure electrical cords away from standing water or heavy machinery.",
    "IIF Reminder: Always wear required PPE (Personal Protective Equipment) on site."
)

# 1. Display the randomized Daily Safety Tip
$TodaysTip = $SafetyTips | Get-Random
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "      ADOLFSON & PETERSON - IIF SAFETY PROTOCOL           " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "DAILY IT SAFETY TIP: $TodaysTip" -ForegroundColor White
Write-Host ""

# 2. Validation Gate
if (-not $ForceSkipAcknowledgement) {
    Write-Warning "STOP: You must conduct a visual hazard assessment before touching equipment."
    $response = Read-Host "Have you inspected the IT work area for trip/electrical hazards? (Y/N)"
    if ($response -ne 'Y') {
        Throw "Work halted. Must acknowledge safety check before proceeding."
    }
}

# 3. Log the "Site Arrival" for safety accountability
$LogPath = "C:\Logs\FieldSafetyLog.csv"
$Entry = [PSCustomObject]@{
    Timestamp = Get-Date
    User      = $env:USERNAME
    SiteID    = $JobSiteID
    SafetyAck = $true
}

if ($PSCmdlet.ShouldProcess($LogPath, "Log safety acknowledgement")) {
    $Entry | Export-Csv -Path $LogPath -Append -NoTypeInformation -Force
    Write-Host "✅ Safety acknowledgement logged to '$LogPath'. Cleared to work." -ForegroundColor Cyan
}
