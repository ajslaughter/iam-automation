# WARNING: Run on test DC only

Write-Host "Starting domain cleanup..." -ForegroundColor Yellow

# 1. Delete all custom GPOs (except default)
Get-GPO -All | Where-Object { $_.DisplayName -notmatch "Default Domain|Default Domain Controllers" } | ForEach-Object {
    Write-Host "Removing GPO: $($_.DisplayName)"
    Remove-GPO -Guid $_.Id -Confirm:$false
}

# 2. Delete all custom security groups (not built-in)
Get-ADGroup -Filter * -SearchBase "OU=ChoiceBank,DC=ad,DC=slaughter,DC=test" | ForEach-Object {
    Write-Host "Removing group: $($_.Name)"
    Remove-ADGroup -Identity $_ -Confirm:$false
}

# 3. Delete all users in ChoiceBank
Get-ADUser -Filter * -SearchBase "OU=ChoiceBank,DC=ad,DC=slaughter,DC=test" | ForEach-Object {
    Write-Host "Removing user: $($_.SamAccountName)"
    Remove-ADUser -Identity $_ -Confirm:$false
}

# 4. Recursively delete the ChoiceBank OU and everything under it
Write-Host "Removing OU: ChoiceBank"
Remove-ADOrganizationalUnit -Identity "OU=ChoiceBank,DC=ad,DC=slaughter,DC=test" -Recursive -Confirm:$false

Write-Host "✅ Domain cleanup complete. You're now ready to re-run setup_environment.ps1." -ForegroundColor Green
