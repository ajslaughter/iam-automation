# list_user_groups.ps1
param (
    [string]$Username
)

try {
    if (Get-Command -Name Get-ADUser -ErrorAction SilentlyContinue) {
        $groups = Get-ADUser $Username -Properties MemberOf | Select-Object -ExpandProperty MemberOf
        Write-Host "✅ '$Username' is a member of the following groups:"
        $groups | ForEach-Object { Write-Host "- $_" }
    } else {
        Write-Host "ℹ️ Simulated output: '$Username' would be listed with associated group memberships."
        Write-Host "- CN=Finance,OU=Groups,DC=corp,DC=local"
        Write-Host "- CN=VPNUsers,OU=Groups,DC=corp,DC=local"
    }
}
catch {
    Write-Host "❌ Error retrieving group memberships for '$Username': $_"
}
