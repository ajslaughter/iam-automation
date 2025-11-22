<#
.SYNOPSIS
    Rapidly diagnoses field site network connectivity.
.DESCRIPTION
    Tests key network dependencies (Gateway, Internet, VPN, Meraki Cloud).
#>
[CmdletBinding()]
param(
    [string]$CriticalGateway = "8.8.8.8",
    [string]$CorpVPNEndpoint = "vpn.a-p.com",
    [string]$MerakiDashboard = "dashboard.meraki.com"
)

function Test-Latency {
    param([string]$Target)
    try {
        $ping = Test-Connection -ComputerName $Target -Count 3 -ErrorAction Stop
        $avg = ($ping.ResponseTime | Measure-Object -Average).Average
        return [PSCustomObject]@{ Status = "UP"; LatencyMs = [math]::Round($avg, 2) }
    }
    catch {
        return [PSCustomObject]@{ Status = "DOWN"; LatencyMs = 0 }
    }
}

Write-Host "--- Starting Field Site Connectivity Diagnostics ---" -ForegroundColor Cyan

# 1. Local Interface Check
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
if (-not $adapters) {
    Write-Error "[CRITICAL] No active network adapters found."
    return
}
Write-Host " [OK] Active Adapter Found: $($adapters.Name)" -ForegroundColor Green

# 2. Gateway & Internet Check
$internet = Test-Latency -Target $CriticalGateway
if ($internet.Status -eq "UP") {
    Write-Host " [OK] Internet Reachability to $CriticalGateway : UP ($($internet.LatencyMs) ms)" -ForegroundColor Green
} else {
    Write-Host " [FAIL] Internet Reachability to $CriticalGateway : DOWN" -ForegroundColor Red
}

# 3. Corporate VPN Check
$vpn = Test-Latency -Target $CorpVPNEndpoint
if ($vpn.Status -eq "UP") {
    Write-Host " [OK] Corporate VPN Endpoint ($CorpVPNEndpoint) : UP" -ForegroundColor Green
} else {
    Write-Host " [FAIL] Corporate VPN Endpoint ($CorpVPNEndpoint) : DOWN" -ForegroundColor Red
}

# 4. Meraki Cloud Check
$meraki = Test-Latency -Target $MerakiDashboard
if ($meraki.Status -eq "UP") {
    Write-Host " [OK] Meraki Cloud Controller ($MerakiDashboard) : UP" -ForegroundColor Green
} else {
    Write-Host " [FAIL] Meraki Cloud Controller ($MerakiDashboard) : DOWN" -ForegroundColor Red
}

Write-Host "--- Diagnostics Complete ---" -ForegroundColor Cyan
