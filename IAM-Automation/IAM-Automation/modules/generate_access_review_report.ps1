$users = Get-ADUser -Filter * -Properties MemberOf | Select-Object SamAccountName, MemberOf

$report = foreach ($user in $users) {
    [PSCustomObject]@{
        User = $user.SamAccountName
        Groups = ($user.MemberOf | ForEach-Object { (Get-ADGroup $_).Name }) -join '; '
    }
}

$report | Export-Csv -Path "AccessReviewReport.csv" -NoTypeInformation
Write-Log "Access review report generated."
