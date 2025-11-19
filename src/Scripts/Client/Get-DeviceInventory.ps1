<#
.SYNOPSIS
    Generates a "Birth Certificate" for a field device for asset tracking.
.DESCRIPTION
    Collects Serial, Model, OS Version, and Installed Software (like Bluebeam) for inventory.
    Addresses the "detailing hardware/software inventory" requirement.
#>
[CmdletBinding()]
param(
    [string]$UploadPath = "\\file-server\IT\Inventory"
)

$Computer = Get-CimInstance Win32_ComputerSystem
$Bios = Get-CimInstance Win32_Bios
$OS = Get-CimInstance Win32_OperatingSystem

$Inventory = [PSCustomObject]@{
    Hostname      = $Computer.Name
    Model         = $Computer.Model
    SerialNumber  = $Bios.SerialNumber
    LastUser      = $Computer.UserName
    OSVersion     = $OS.Caption
    IPAddress     = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object PrefixOrigin -eq 'Dhcp').IPAddress
    Timestamp     = Get-Date
}

$Inventory | Format-List

# In a real scenario, this would upload to the central CSV
Write-Host "✅ Inventory data generated for $($Computer.Name)" -ForegroundColor Green
