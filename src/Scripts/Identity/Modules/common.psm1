# Import the centralized logging module
$loggingModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\Modules\IamLab.Logging\IamLab.Logging.psm1'
if (Test-Path -Path $loggingModulePath) {
    Import-Module -Name $loggingModulePath -Force
} else {
    Write-Warning "Logging module not found at $loggingModulePath"
}

# Backward compatibility alias
New-Alias -Name Log-Message -Value Write-IamLog -Force -ErrorAction SilentlyContinue

