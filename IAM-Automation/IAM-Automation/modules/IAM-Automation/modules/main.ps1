Write-Host "IAM Automation Toolkit Menu"
Write-Host "1. Provision user"
Write-Host "2. Reset password"
...
switch (Read-Host "Select an option") {
    1 { .\provision_user.ps1 }
    2 { .\reset_password.ps1 }
}
