# File: Disable-LabUser.ps1

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory)]
    [string]$Username
)

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Modules/common.psm1')

try {
    if ($PSCmdlet.ShouldProcess($Username, "Disable Active Directory User")) {
        Write-IamLog -Message "Disabling user '$Username'..." -Level Information
        
        Set-ADUser -Identity $Username -Enabled $false -ErrorAction Stop
        
        Write-IamLog -Message "User '$Username' disabled successfully." -Level Information
    }
}
catch {
    Write-IamLog -Message "Error disabling user '$Username': $($_.Exception.Message)" -Level Error
    throw
}
