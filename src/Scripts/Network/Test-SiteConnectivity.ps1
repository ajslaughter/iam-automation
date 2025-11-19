<#
.SYNOPSIS
    Rapidly diagnoses field site network connectivity, focusing on Meraki and VPN access.
.DESCRIPTION
    Tests key network dependencies (Gateway, Internet, VPN, Meraki Cloud) for rapid fault isolation.
    Addresses the job requirement for TCP/IP troubleshooting and diagnostic tools.
#>
[CmdletBinding()]
param(
    [string]$CriticalGateway = "8.8.8.8",
    [string]$CorpVPNEndpoint = "vpn.a-p.com",
    [string]$MerakiDashboard = "dashboard.meraki.com"
)

function Test-Latency {
    param([string]$Target)
    $ping = Test-Connection -ComputerName $Target -Count 3 -ErrorAction SilentlyContinue
    if ($ping) {
        $avg = ($ping.ResponseTime | Measure-Object -Average).Average
        return [PSCustomObject]@{ Status = "UP"; LatencyMs = [math]::Round($avg, 2) }
    }
    return [PSCustomObject]@{ Status = "DOWN"; LatencyMs = $null }
}

Write-Host "🔍 Starting Field Site Connectivity Diagnostics..." -ForegroundColor Cyan

# 1. Local Interface Check (Physical Layer)
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
if (-not $adapters) {
    Write-Error "❌ CRITICAL: No active network adapters found. Check physical layer."
    return
}
Write-Host "✅ Active Adapter: $($adapters.Name -join ', ')"

# 2. Gateway & Internet Check (Transport Layer)
$internet = Test-Latency -Target $CriticalGateway
Write-Host "   - Internet Reachability to $CriticalGateway: $($internet.Status)" -ForegroundColor ($internet.Status -eq "UP" ? "Green" : "Red")
if ($internet.Status -eq "UP") { Write-Host "     - Average Latency: $($internet.LatencyMs)ms" }

# 3. Corporate VPN Check (Application Layer)
$vpn = Test-Latency -Target $CorpVPNEndpoint
Write-Host "   - Corporate VPN Endpoint ($CorpVPNEndpoint): $($vpn.Status)" -ForegroundColor ($vpn.Status -eq "UP" ? "Green" : "Red")

# 4. Meraki Cloud Check (JD Specific)
$meraki = Test-Latency -Target $MerakiDashboard
Write-Host "   - Meraki Cloud Controller ($MerakiDashboard): $($meraki.Status)" -ForegroundColor ($meraki.Status -eq "UP" ? "Green" : "Red")
if ($meraki.Status -ne "UP") { Write-Warning "⚠️ Meraki issues can block MDM and firewall policy updates." }

# 5. Wireless Signal Strength (If applicable)
if ($adapters | Where-Object { $_.InterfaceDescription -match "Wi-Fi|Wireless" }) {
    $signal = (netsh wlan show interfaces) -match 'Signal'
    Write-Host "   - $(($signal -split ':')[-1].Trim()) signal strength reported on adapter." -ForegroundColor Yellow
}
Write-Host "✅ Diagnostics Complete." -ForegroundColor Cyan
