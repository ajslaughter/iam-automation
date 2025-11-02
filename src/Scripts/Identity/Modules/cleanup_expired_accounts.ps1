# cleanup_expired_accounts.ps1

try {
    $expiredUsers = Get-ADUser -Filter {AccountExpirationDate -lt (Get-Date)} -Properties AccountExpirationDate
    if ($expiredUsers.Count -eq 0) {
        Write-Host "No expired accounts found."
    } else {
        foreach ($user in $expiredUsers) {
            Disable-ADAccount -Identity $user.SamAccountName
            Write-Host "Disabled expired account: $($user.SamAccountName)"
        }
    }
}
catch {
    Write-Host "Error during expired account cleanup: $_"
}
