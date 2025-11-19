<#
.SYNOPSIS
    Enforces "Incident and Injury Free" (IIF) culture by presenting a safety brief.

.DESCRIPTION
    This script displays a random safety tip related to IT in construction environments.
    It requires the user to visually scan their area for hazards and acknowledge safety protocols.
    Acknowledgements are logged to a local CSV file.

.EXAMPLE
    .\Invoke-SafetyBrief.ps1

.NOTES
    File Name      : Invoke-SafetyBrief.ps1
    Author         : DevOps Team
    Prerequisite   : PowerShell v5.1+
#>

[CmdletBinding()]
param()

begin {
    $ErrorActionPreference = "Stop"
    $LogPath = "C:\Logs\FieldSafetyLog.csv"
    
    # Ensure Log Directory Exists
    $LogDir = Split-Path -Path $LogPath -Parent
    if (-not (Test-Path -Path $LogDir)) {
        New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
        Write-Verbose "Created log directory: $LogDir"
    }

    $SafetyTips = @(
        "Always maintain 3 points of contact when using ladders.",
        "Tape down all temporary network cables to prevent trip hazards.",
        "Wear appropriate PPE (Hard hat, Vest, Glasses) when on active construction sites.",
        "Hydrate frequently, especially when working in non-conditioned server closets.",
        "Lift with your legs, not your back, when moving server equipment.",
        "Ensure all power tools and extension cords are inspected before use."
    )
}

process {
    try {
        Clear-Host
        Write-Host "==========================================" -ForegroundColor Yellow
        Write-Host "   ADOLFSON & PETERSON - SAFETY BRIEF     " -ForegroundColor Yellow
        Write-Host "==========================================" -ForegroundColor Yellow
        Write-Host ""

        # Select and Display Random Tip
        $Tip = $SafetyTips | Get-Random
        Write-Host "TODAY'S SAFETY FOCUS:" -ForegroundColor White
        Write-Host "$Tip" -ForegroundColor Cyan
        Write-Host ""

        # User Acknowledgement
        Write-Host "Please visually scan your immediate area for potential hazards." -ForegroundColor Gray
        $Response = Read-Host "Do you acknowledge that your work area is safe? (Y/N)"

        if ($Response -match "^[Yy]") {
            $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $User = $env:USERNAME
            $SiteID = $env:COMPUTERNAME # Using ComputerName as proxy for SiteID in this context

            $LogEntry = [PSCustomObject]@{
                Timestamp = $Timestamp
                User      = $User
                SiteID    = $SiteID
                Action    = "Acknowledged"
            }

            # Append to CSV
            $LogEntry | Export-Csv -Path $LogPath -Append -NoTypeInformation
            
            Write-Host "Safety check acknowledged. Proceeding..." -ForegroundColor Green
            Start-Sleep -Seconds 1
        }
        else {
            Write-Warning "Safety check declined. Work cannot proceed until safety is verified."
            Write-Host "Please address any hazards and re-run the safety brief." -ForegroundColor Red
            throw "Safety Check Declined by User."
        }
    }
    catch {
        Write-Error "Error during safety brief: $_"
        exit 1
    }
}

end {
    Write-Verbose "Safety brief execution completed."
}
