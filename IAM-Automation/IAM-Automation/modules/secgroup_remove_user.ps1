param (
    [string]$Username,
    [string]$GroupName
)

try {
    Remove-ADGroupMember -Identity $GroupName -Members $Username -Confirm:$false
    Write-Log "User '$Username' removed from security group '$GroupName'."
} catch {
    Write-Log "Error removing user from group '$GroupName': $_"
}
