# File: create_gpo.ps1
param (
    [string]$GPOName,
    [string]$Description = "Created by IAM Automation Toolkit"
)

try {
    New-GPO -Name $GPOName -Comment $Description | Out-Null
    Write-Log "GPO '$GPOName' created successfully."
} catch {
    Write-Log "Error creating GPO '$GPOName': $_"
}
