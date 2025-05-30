param (
    [string]$CsvPath
)

$users = Import-Csv $CsvPath

foreach ($user in $users) {
    Disable-ADAccount -Identity $user.Username
    Get-ADUser $user.Username | Get-ADPrincipalGroupMembership | ForEach-Object {
        Remove-ADGroupMember -Identity $_.SamAccountName -Members $user.Username -Confirm:$false
    }
    Write-Log "Terminated and cleaned up user '$($user.Username)'."
}
