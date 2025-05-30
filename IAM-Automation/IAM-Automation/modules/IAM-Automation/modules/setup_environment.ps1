# Setup script for AD lab environment (OUs, users, groups)
# Domain: ad.slaughter.test

# ========== CREATE OUs ==========
Write-Host "Creating top-level OU: ChoiceBank"
New-ADOrganizationalUnit -Name "ChoiceBank" -Path "DC=ad,DC=slaughter,DC=test" -ProtectedFromAccidentalDeletion:$false

Write-Host "Creating department OUs..."
"Finance","IT","HR","Compliance" | ForEach-Object {
    New-ADOrganizationalUnit -Name $_ -Path "OU=ChoiceBank,DC=ad,DC=slaughter,DC=test" -ProtectedFromAccidentalDeletion:$false
}

Write-Host "Creating region OUs..."
"Fargo","Bismarck","Minneapolis" | ForEach-Object {
    New-ADOrganizationalUnit -Name $_ -Path "OU=ChoiceBank,DC=ad,DC=slaughter,DC=test" -ProtectedFromAccidentalDeletion:$false
}

# ========== CREATE USERS ==========
$users = @(
    @{ Name = "John Smith"; Sam = "jsmith"; OU = "Finance" },
    @{ Name = "Alex Taylor"; Sam = "ataylor"; OU = "IT" },
    @{ Name = "Maria Brown"; Sam = "mbrown"; OU = "HR" },
    @{ Name = "Luke White"; Sam = "lwhite"; OU = "Compliance" },
    @{ Name = "Kate Murphy"; Sam = "kmurphy"; OU = "Fargo" }
)

foreach ($u in $users) {
    $dn = "OU=$($u.OU),OU=ChoiceBank,DC=ad,DC=slaughter,DC=test"
    New-ADUser -Name $u.Name -SamAccountName $u.Sam -UserPrincipalName "$($u.Sam)@ad.slaughter.test" `
        -AccountPassword (ConvertTo-SecureString "Password123!" -AsPlainText -Force) `
        -Enabled $true -Path $dn
    Write-Host "Created user: $($u.Sam) in $($u.OU)"
}

# ========== CREATE SECURITY GROUPS ==========
$groups = @("SG_FinanceUsers","SG_ITAdmins","SG_HRViewers","SG_AccessReviewers")

foreach ($g in $groups) {
    New-ADGroup -Name $g -GroupScope Global -GroupCategory Security -Path "OU=ChoiceBank,DC=ad,DC=slaughter,DC=test"
    Write-Host "Created group: $g"
}

# ========== ASSIGN USERS TO GROUPS ==========
Add-ADGroupMember -Identity "SG_FinanceUsers" -Members "jsmith"
Add-ADGroupMember -Identity "SG_ITAdmins" -Members "ataylor"
Add-ADGroupMember -Identity "SG_HRViewers" -Members "mbrown"
Add-ADGroupMember -Identity "SG_AccessReviewers" -Members "lwhite","ataylor"

Write-Host "`n✅ Environment setup complete. You can now run your IAM automation scripts."
