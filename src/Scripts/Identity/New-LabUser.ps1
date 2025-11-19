<#
.SYNOPSIS
    Provisions a new user in the lab environment.

.DESCRIPTION
    Creates a new Active Directory user with the specified username and password.
    Uses configuration from 'src/config/config.psd1' for domain details.

.PARAMETER Username
    The SAMAccountName for the new user.

.PARAMETER Path
    Optional. The Distinguished Name (DN) of the OU to create the user in.
    Defaults to the 'DefaultOU' defined in config.psd1.

.PARAMETER Password
    The initial password for the account.

.PARAMETER Enabled
    Switch to enable the account immediately upon creation.

.EXAMPLE
    New-LabUser -Username 'jdoe' -Enabled
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory)]
    [string]$Username,

    [Parameter()]
    [string]$Path,

    [Parameter()]
    [securestring]$Password,

    [Parameter()]
    [switch]$Enabled
)

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Modules/common.psm1')

# Load Configuration
$configPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\config\config.psd1'
if (Test-Path -Path $configPath) {
    $config = Import-PowerShellDataFile -Path $configPath
} else {
    throw "Configuration file not found at $configPath"
}

try {
    $domain = $config.Domain
    if (-not $domain) { $domain = 'corp.local' }

    $params = @{
        Name = $Username
        SamAccountName = $Username
        UserPrincipalName = "$Username@$domain"
        AccountPassword = $Password
        Enabled = $Enabled
        ErrorAction = 'Stop'
    }

    if ($Path) {
        $params['Path'] = $Path
    } elseif ($config.DefaultOU) {
        $params['Path'] = $config.DefaultOU
    }


    if ($Path) {
        $params['Path'] = $Path
    }

    if ($PSCmdlet.ShouldProcess($Username, "Create Active Directory User")) {
        Write-IamLog -Message "Creating user '$Username'..." -Level Information
        New-ADUser @params
        Write-IamLog -Message "User '$Username' created successfully." -Level Information
    }
}
catch {
    Write-IamLog -Message "Error creating user '$Username': $($_.Exception.Message)" -Level Error
    throw
}
