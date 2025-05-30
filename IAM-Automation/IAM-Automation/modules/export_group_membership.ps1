param (
    [string]$GroupName
)

$members = Get-ADGroupMember -Identity $GroupName | Select-Object Name, SamAccountName, objectClass
$members | Export-Csv -Path "$GroupName-members.csv" -NoTypeInformation
Write-Log "Exported group membership for '$GroupName'."
