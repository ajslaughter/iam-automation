<#
.SYNOPSIS
    Automated remediation for common field office printing issues.
.DESCRIPTION
    Restarts the print spooler, clears stuck print jobs, and attempts to reach mapped print servers.
    Addresses the "printing" and "peripheral hardware" support requirements in the JD.
#>
[CmdletBinding()]
param()

Write-Host "🖨️  Diagnosing Print System..." -ForegroundColor Cyan

# 1. Clear Stuck Jobs
$Spooler = Get-Service Spooler
if ($Spooler.Status -eq 'Running') {
    Stop-Service Spooler -Force
}

$StuckJobs = Get-ChildItem "C:\Windows\System32\spool\PRINTERS\*.*"
if ($StuckJobs) {
    Remove-Item "C:\Windows\System32\spool\PRINTERS\*.*" -Force
    Write-Host "   - Cleared $($StuckJobs.Count) stuck print jobs." -ForegroundColor Yellow
} else {
    Write-Host "   - No stuck print queues found." -ForegroundColor Green
}

Start-Service Spooler
Write-Host "✅ Print Spooler Restarted." -ForegroundColor Green

# 2. Test Print Server Connectivity
$PrintServer = "print-server.corp.local" # Example
if (Test-Connection -ComputerName $PrintServer -Count 1 -Quiet) {
    Write-Host "✅ Connection to Print Server ($PrintServer) is Good." -ForegroundColor Green
} else {
    Write-Error "❌ Print Server ($PrintServer) Unreachable. Check VPN."
}
