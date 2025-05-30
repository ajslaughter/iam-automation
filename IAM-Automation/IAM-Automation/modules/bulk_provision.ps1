# bulk_provision.ps1
Import-Csv users.csv | ForEach-Object {
    .\provision_user.ps1 -FirstName $_.FirstName -LastName $_.LastName -Username $_.Username -Department $_.Department -Role $_.Role
}
