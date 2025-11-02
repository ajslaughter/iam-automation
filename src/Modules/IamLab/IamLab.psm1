Set-StrictMode -Version Latest

$script:ModuleRoot = Split-Path -Parent $PSCommandPath
$script:RepositoryRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $script:ModuleRoot))

$privatePath = Join-Path -Path $script:ModuleRoot -ChildPath 'Private'
if (Test-Path -LiteralPath $privatePath) {
    Get-ChildItem -Path $privatePath -Filter '*.ps1' | ForEach-Object { . $_.FullName }
}

$publicPath = Join-Path -Path $script:ModuleRoot -ChildPath 'Public'
if (Test-Path -LiteralPath $publicPath) {
    Get-ChildItem -Path $publicPath -Filter '*.ps1' | ForEach-Object { . $_.FullName }
}
