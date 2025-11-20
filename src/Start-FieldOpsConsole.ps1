<#
.SYNOPSIS
    The central command interface for Adolfson & Peterson Field Operations.
.DESCRIPTION
    A unified CLI menu that enforces IIF Safety compliance before unlocking
    technical tools (Network Diagnostics, Inventory, Printing, Workstation Prep).
#>
param()

# --- HELPER FUNCTIONS ---
function Show-Header {
    Clear-Host
    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host "   A D O L F S O N  &  P E T E R S O N   C O N S T. " -ForegroundColor White
    Write-Host "          F I E L D   O P S   C O N S O L E         " -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host "User: $env:USERNAME | Host: $env:COMPUTERNAME | $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor DarkGray
    Write-Host ""
}

function Invoke-Tool {
    param($ScriptPath, $Args)
    if (Test-Path $ScriptPath) {
        & $ScriptPath @Args
        Write-Host "`n[PRESS ENTER TO CONTINUE]" -ForegroundColor Yellow
        $null = Read-Host
    } else {
        Write-Error "Tool not found: $ScriptPath"
        Start-Sleep -Seconds 2
    }
}

# --- INITIALIZATION ---
$SafetyUnlocked = $false
$ScriptRoot = "$PSScriptRoot\Scripts"

# --- MAIN LOOP ---
do {
    Show-Header
    
    # Menu Options
    Write-Host " [1] 🦺  DAILY SAFETY BRIEFING (IIF Compliance)" -ForegroundColor ('Yellow', 'Green')[[int]$SafetyUnlocked]
    
    if ($SafetyUnlocked) {
        Write-Host " [2] 📡  Site Connectivity Test (Meraki/VPN)"
        Write-Host " [3] 🕸️   Packet Capture (Netsh Trace)"
        Write-Host " [4] 🖨️   Repair Print System"
        Write-Host " [5] 💻  Workstation Prep (SCCM/Imaging)"
        Write-Host " [6] 📝  Device Asset Inventory"
    } else {
        Write-Host " [2-6] 🔒 (LOCKED - REQUIRES SAFETY ACKNOWLEDGEMENT)" -ForegroundColor DarkGray
    }
    Write-Host " [Q] Quit"
    Write-Host ""
    
    $Selection = Read-Host " Select an Action"

    switch ($Selection) {
        '1' { 
            try {
                & "$ScriptRoot\Safety\Invoke-SafetyBrief.ps1" -ErrorAction Stop
                $SafetyUnlocked = $true
            } catch {
                $SafetyUnlocked = $false
            }
            Write-Host "`n[PRESS ENTER TO CONTINUE]"
            $null = Read-Host
        }
        '2' { if ($SafetyUnlocked) { Invoke-Tool "$ScriptRoot\Network\Test-SiteConnectivity.ps1" } }
        '3' { if ($SafetyUnlocked) { Invoke-Tool "$ScriptRoot\Network\Invoke-QuickPacketCapture.ps1" } }
        '4' { if ($SafetyUnlocked) { Invoke-Tool "$ScriptRoot\Client\Repair-PrintSystem.ps1" } }
        '5' { 
            if ($SafetyUnlocked) { 
                $Role = Read-Host "Select Profile (Office/Field)"
                Invoke-Tool "$ScriptRoot\Client\Invoke-WorkstationPrep.ps1" -RoleProfile $Role
            } 
        }
        '6' { if ($SafetyUnlocked) { Invoke-Tool "$ScriptRoot\Client\Get-DeviceInventory.ps1" } }
        'q' { exit }
        'Q' { exit }
    }
} until ($Selection -eq 'Q')
