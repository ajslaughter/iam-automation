# File: secgroup_add_user.ps1
param (
    [string]$Username,
    [string]$GroupName
)

try {
    Add-ADGroupMember -Identity $GroupName -Members $Username
    Write-Log "User '$Username' added to security group '$GroupName' successfully."
}
catch {
    Write-Log "Error adding user '$Username' to group '$GroupName': $_"
}
