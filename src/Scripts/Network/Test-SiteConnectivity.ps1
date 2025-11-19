<#
.SYNOPSIS
    Diagnoses connection issues at remote job sites.

.DESCRIPTION
    This script performs a series of connectivity tests to validate the network health of a remote site.
    It checks for active network adapters, tests latency to public DNS, and verifies TCP connectivity
    to corporate VPN and Meraki dashboard endpoints.

.EXAMPLE
    .\Test-SiteConnectivity.ps1

.NOTES
    File Name      : Test-SiteConnectivity.ps1
    Author         : DevOps Team
    Prerequisite   : PowerShell v5.1+
#>

[CmdletBinding()]
param()

function Get-WifiSignalStrength {
    if ($IsWindows) {
        $Wifi = netsh wlan show interfaces
        $Signal = $Wifi | Select-String "Signal"
        if ($Signal) {
            return $Signal.ToString().Trim()
        }
    }
    return "N/A"
}

function Write-Status {
    param (
        [string]$TestName,
        [bool]$Success,
        [string]$Message
    )
    
    if ($Success) {
        Write-Host "[$TestName] SUCCESS: $Message" -ForegroundColor Green
    } else {
        Write-Host "[$TestName] FAILURE: $Message" -ForegroundColor Red
    }
}

process {
    Write-Host "Starting Site Connectivity Diagnostics..." -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan

    # 1. Check for Active Adapters
    $Adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    if ($Adapters) {
        Write-Status -TestName "Adapter Check" -Success $true -Message "Found $($Adapters.Count) active adapter(s)."
        foreach ($Adapter in $Adapters) {
            Write-Host "  - $($Adapter.Name) ($($Adapter.InterfaceDescription))" -ForegroundColor Gray
            if ($Adapter.InterfaceDescription -match "Wireless|Wi-Fi") {
                $Signal = Get-WifiSignalStrength
                Write-Host "    Signal Strength: $Signal" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Status -TestName "Adapter Check" -Success $false -Message "No active network adapters found!"
        exit 1
    }

    # 2. Test Latency (Public IP)
    $PublicIP = "8.8.8.8"
    try {
        $Ping = Test-Connection -ComputerName $PublicIP -Count 1 -ErrorAction Stop
        Write-Status -TestName "Internet Latency" -Success $true -Message "Ping to $PublicIP successful (${($Ping.ResponseTime)}ms)."
    } catch {
        Write-Status -TestName "Internet Latency" -Success $false -Message "Unable to ping $PublicIP."
    }

    # 3. Test Corporate VPN (TCP)
    $VpnHost = "vpn.example.com"
    $VpnPort = 443
    try {
        # Using Test-NetConnection for TCP check
        $TcpCheck = Test-NetConnection -ComputerName $VpnHost -Port $VpnPort -InformationLevel Quiet
        if ($TcpCheck) {
            Write-Status -TestName "VPN Reachability" -Success $true -Message "Connection to $VpnHost on port $VpnPort successful."
        } else {
            Write-Status -TestName "VPN Reachability" -Success $false -Message "Connection to $VpnHost on port $VpnPort failed."
        }
    } catch {
        Write-Status -TestName "VPN Reachability" -Success $false -Message "Error testing connection to $VpnHost."
    }

    # 4. Test Meraki Dashboard
    $MerakiHost = "dashboard.meraki.com"
    $MerakiPort = 443
    try {
        $TcpCheck = Test-NetConnection -ComputerName $MerakiHost -Port $MerakiPort -InformationLevel Quiet
        if ($TcpCheck) {
            Write-Status -TestName "Meraki Dashboard" -Success $true -Message "Connection to $MerakiHost on port $MerakiPort successful."
        } else {
            Write-Status -TestName "Meraki Dashboard" -Success $false -Message "Connection to $MerakiHost on port $MerakiPort failed."
        }
    } catch {
        Write-Status -TestName "Meraki Dashboard" -Success $false -Message "Error testing connection to $MerakiHost."
    }

    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "Diagnostics Completed." -ForegroundColor Cyan
}
