# File: reset_password.ps1
param (
    [string]$Username
)

# Prompt securely for the new password
$NewPassword = Read-Host "Enter new password for $Username" -AsSecureString

try {
    Set-ADAccountPassword -Identity $Username -NewPassword $NewPassword -Reset
    Set-ADUser -Identity $Username -ChangePasswordAtLogon $true
    Write-Log "Password for $Username reset successfully."
}
catch {
    Write-Log "Error resetting password for $Username: $_"
}
