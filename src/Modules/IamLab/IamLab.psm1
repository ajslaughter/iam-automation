using namespace System.Management.Automation

if (-not (Get-Module -Name Microsoft.PowerShell.SecretManagement)) {
    try {
        Import-Module Microsoft.PowerShell.SecretManagement -ErrorAction Stop | Out-Null
    } catch {
        Write-Verbose 'Microsoft.PowerShell.SecretManagement module not available; falling back to lab secrets when permitted.'
    }
}

function Get-IamLabSecret {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [switch]$AsCredential,

        [Parameter()]
        [switch]$AllowFallback
    )

    $secretParams = @{ Name = $Name; ErrorAction = 'Stop' }
    if ($AsCredential) {
        $secretParams['AsCredential'] = $true
    } else {
        $secretParams['AsPlainText'] = $true
    }

    try {
        return Get-Secret @secretParams
    } catch {
        Write-Verbose "SecretManagement lookup for '$Name' failed: $($_.Exception.Message)"
        if (-not $AllowFallback) {
            throw
        }
    }

    $repoRoot = Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..')
    $fallbackPath = Join-Path -Path $repoRoot -ChildPath 'config/secrets.json'
    if (-not (Test-Path -Path $fallbackPath)) {
        throw "Fallback secrets file '$fallbackPath' not found. Register a SecretManagement vault instead."
    }

    $json = Get-Content -Path $fallbackPath -Raw | ConvertFrom-Json
    if (-not $json.$Name) {
        throw "Secret '$Name' not present in fallback configuration."
    }

    $entry = $json.$Name
    if ($AsCredential) {
        if (-not ($entry.UserName -and $entry.Password)) {
            throw "Fallback entry for '$Name' does not include UserName and Password."
        }
        return New-Object System.Management.Automation.PSCredential($entry.UserName, (ConvertTo-SecureString $entry.Password -AsPlainText -Force))
    }

    if ($entry.Password) {
        return $entry.Password
    }

    return $entry
}

function Get-IamLabCredential {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [switch]$AllowFallback
    )

    return Get-IamLabSecret -Name $Name -AsCredential -AllowFallback:$AllowFallback.IsPresent
}

function Get-IamLabFeatureFlag {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [switch]$AsBoolean
    )

    $repoRoot = Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\\..\\..')
    $featurePath = Join-Path -Path $repoRoot -ChildPath 'config/features.json'
    if (-not (Test-Path -Path $featurePath)) {
        Write-Verbose "Feature configuration '$featurePath' not found. Returning $false."
        return $false
    }

    $config = Get-Content -Path $featurePath -Raw | ConvertFrom-Json
    $value = $config.$Name
    if ($AsBoolean) {
        return [bool]$value
    }
    return $value
}

function Invoke-IamLabSelfTest {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$SecretName = 'IamLab-DefaultAdmin'
    )

    $result = [ordered]@{
        SecretName        = $SecretName
        SecretManagement  = $false
        FallbackAvailable = $false
    }

    try {
        $secret = Get-IamLabSecret -Name $SecretName -AsCredential -ErrorAction Stop
        if ($secret -is [PSCredential]) {
            $result.SecretManagement = $true
            $result.FallbackAvailable = $false
            return [pscustomobject]$result
        }
    } catch {
        Write-Verbose "Primary secret lookup failed: $($_.Exception.Message)"
    }

    try {
        $secret = Get-IamLabSecret -Name $SecretName -AsCredential -AllowFallback -ErrorAction Stop
        if ($secret -is [PSCredential]) {
            $result.FallbackAvailable = $true
        }
    } catch {
        Write-Verbose "Fallback secret lookup failed: $($_.Exception.Message)"
    }

    [pscustomobject]$result
}

Export-ModuleMember -Function Get-IamLabSecret, Get-IamLabCredential, Invoke-IamLabSelfTest, Get-IamLabFeatureFlag
