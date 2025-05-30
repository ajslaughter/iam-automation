param (
    [int]$DaysInactive = 90
)

$time = (Get-Date).AddDays(-$DaysInactive)

$staleUsers = Get-ADUser -Filter { LastLogonDate -lt $time -and Enabled -eq $true } -Properties LastLogonDate

foreach ($user in $staleUsers) {
    Disable-ADAccount -Identity $user.SamAccountName
    Write-Log "Disabled stale account: $($user.SamAccountName)"
}
