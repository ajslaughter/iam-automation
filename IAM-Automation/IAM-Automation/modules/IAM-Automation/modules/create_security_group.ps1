# File: create_security_group.ps1

param (
    [string]$GroupName,
    [string]$OU = "OU=Groups,DC=yourdomain,DC=com",
    [string]$Description = "Security group created via automation script"
)

Import-Module "$PSScriptRoot\common.psm1"

try {
    Write-Log "Creating security group: $GroupName"

    New-ADGroup -Name $GroupName `
                -Path $OU `
                -GroupScope Global `
                -GroupCategory Security `
                -Description $Description

    Write-Log "Security group '$GroupName' created successfully in '$OU'."
}
catch {
    Write-Log ("Error creating group '{0}': {1}" -f $GroupName, $_)
}
