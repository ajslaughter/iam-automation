# File: secgroup_add_ou_users.ps1
param (
    [string]$OU,
    [string]$GroupName
)

try {
    $users = Get-ADUser -SearchBase $OU -Filter * | Select-Object -ExpandProperty SamAccountName

    foreach ($user in $users) {
        Add-ADGroupMember -Identity $GroupName -Members $user
        Write-Log "User '$user' added to security group '$GroupName'."
    }
}
catch {
    Write-Log "Error adding OU users to group '$GroupName': $_"
}
