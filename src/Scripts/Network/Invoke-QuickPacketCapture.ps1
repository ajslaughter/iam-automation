<#
.SYNOPSIS
    Runs a native Windows packet capture for troubleshooting complex network issues.
.DESCRIPTION
    Uses 'netsh trace' to capture 60 seconds of network traffic without requiring Wireshark installation.
    Generates an .etl file that can be analyzed later. Addresses JD requirement for "packet capture utilities."
#>
[CmdletBinding()]
param(
    [string]$CaptureDurationSeconds = 60,
    [string]$OutputFolder = "C:\Logs\NetworkTraces"
)

Write-Host "🕸️  Starting Field Network Capture (No Wireshark Required)..." -ForegroundColor Cyan

if (-not (Test-Path $OutputFolder)) { New-Item -Path $OutputFolder -ItemType Directory | Out-Null }
$Filename = "$OutputFolder\Trace_$(Get-Date -Format 'yyyyMMdd-HHmm').etl"

Write-Host "   - Capture started. Please reproduce the issue now." -ForegroundColor Yellow
Write-Host "   - Recording for $CaptureDurationSeconds seconds..."

# Built-in Windows Tracing (No external tools needed - perfect for restricted field laptops)
netsh trace start scenario=NetConnection capture=yes report=yes tracefile=$Filename quiet=$true

Start-Sleep -Seconds $CaptureDurationSeconds

netsh trace stop quiet=$true
Write-Host "✅ Capture Complete. File saved to: $Filename" -ForegroundColor Green
Write-Host "   - Attach this file to the support ticket for deep analysis." -ForegroundColor Gray
