# bulk_provision.ps1
$identityRoot = Join-Path -Path $PSScriptRoot -ChildPath '..'
$script:NewLabUserPath = Join-Path -Path $identityRoot -ChildPath 'New-LabUser.ps1'
$userCsv = Join-Path -Path $PSScriptRoot -ChildPath 'users.csv'

Import-Csv -LiteralPath $userCsv | ForEach-Object {
    & $script:NewLabUserPath -Username $_.Username
}
