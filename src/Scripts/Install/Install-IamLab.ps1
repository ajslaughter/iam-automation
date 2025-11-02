[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [switch]$IncludeGraph,

    [Parameter()]
    [string]$RepositoryName,

    [Parameter()]
    [string]$RepositoryUri,

    [Parameter()]
    [switch]$Force
)

$requiredModules = @('ActiveDirectory', 'GroupPolicy', 'PSWindowsUpdate', 'Microsoft.PowerShell.SecretManagement', 'Pester')
if ($IncludeGraph) {
    $requiredModules += 'Microsoft.Graph.Users', 'Microsoft.Graph.Identity.DirectoryManagement'
}

$missingModules = @()
foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        $missingModules += $module
    }
}

if ($missingModules) {
    Write-Warning "The following modules were not found: $($missingModules -join ', '). Install them before continuing."
}

if ($RepositoryName -and $RepositoryUri) {
    $existingRepo = Get-PSRepository -Name $RepositoryName -ErrorAction SilentlyContinue
    if (-not $existingRepo) {
        if ($PSCmdlet.ShouldProcess($RepositoryUri, "Register PSRepository '$RepositoryName'")) {
            Register-PSRepository -Name $RepositoryName -SourceLocation $RepositoryUri -InstallationPolicy Trusted -ErrorAction Stop
            Write-Verbose "Registered repository '$RepositoryName'."
        }
    } elseif ($Force) {
        if ($PSCmdlet.ShouldProcess($RepositoryUri, "Update PSRepository '$RepositoryName'")) {
            Unregister-PSRepository -Name $RepositoryName -ErrorAction SilentlyContinue
            Register-PSRepository -Name $RepositoryName -SourceLocation $RepositoryUri -InstallationPolicy Trusted -ErrorAction Stop
            Write-Verbose "Updated repository '$RepositoryName'."
        }
    } else {
        Write-Verbose "Repository '$RepositoryName' already registered."
    }
}

$modulePath = Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\IamLab\IamLab.psd1')
if ($PSCmdlet.ShouldProcess($modulePath, 'Import IamLab module')) {
    Import-Module $modulePath -Force -ErrorAction Stop
    Write-Verbose 'IamLab module imported successfully.'
}

$test = Invoke-IamLabSelfTest -Verbose:$VerbosePreference
$summary = [pscustomobject]@{
    ModulePath     = $modulePath
    MissingModules = $missingModules
    SecretReady    = $test.SecretManagement -or $test.FallbackAvailable
}

Write-Output $summary
