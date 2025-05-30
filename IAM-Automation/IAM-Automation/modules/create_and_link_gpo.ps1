# File: create_and_link_gpo.ps1

param (
    [string]$GPOName,
    [string]$OU,
    [string]$Description = "Created and linked by IAM Automation Toolkit"
)

try {
    New-GPO -Name $GPOName -Comment $Description | Out-Null
    New-GPLink -Name $GPOName -Target $OU -Enforced:$false | Out-Null
    Write-Log "GPO '$GPOName' created and linked to OU '$OU' successfully."
}
catch {
    Write-Log "Error during GPO creation or linking for '$GPOName': $_"
}
