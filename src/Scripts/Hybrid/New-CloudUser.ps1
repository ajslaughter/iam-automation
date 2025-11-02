[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)]
    [string]$UserPrincipalName,

    [Parameter(Mandatory)]
    [string]$DisplayName,

    [Parameter()]
    [string]$GivenName,

    [Parameter()]
    [string]$Surname,

    [Parameter()]
    [string]$Department,

    [Parameter()]
    [string]$JobTitle,

    [Parameter()]
    [string]$MailNickname,

    [Parameter()]
    [securestring]$Password,

    [Parameter()]
    [switch]$ForcePasswordChange
)

#requires -Modules Microsoft.Graph.Users

if (-not (Get-IamLabFeatureFlag -Name 'HybridIdentity' -AsBoolean)) {
    Write-Warning 'Hybrid identity automation is disabled. Enable it in config/features.json before running cloud workflows.'
    return
}

Import-Module Microsoft.Graph.Users -ErrorAction Stop | Out-Null

function ConvertTo-ClearText {
    param([securestring]$SecureString)
    if (-not $SecureString) { return $null }
    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    } finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

$existingUser = $null
try {
    $existingUser = Get-MgUser -UserId $UserPrincipalName -ErrorAction Stop
} catch {
    Write-Verbose "User '$UserPrincipalName' not found in Microsoft Entra."
}

if (-not $MailNickname) {
    $MailNickname = ($UserPrincipalName -split '@')[0]
}

if (-not $existingUser) {
    if (-not $Password) {
        throw 'Password is required when creating a new cloud user.'
    }

    if ($PSCmdlet.ShouldProcess($UserPrincipalName, 'Create Microsoft Entra user')) {
        $passwordProfile = @{ Password = ConvertTo-ClearText $Password; ForceChangePasswordNextSignIn = $ForcePasswordChange.IsPresent }
        Write-Verbose "Creating user '$UserPrincipalName' with display name '$DisplayName'."
        New-MgUser -AccountEnabled:$true -UserPrincipalName $UserPrincipalName -DisplayName $DisplayName -GivenName $GivenName -Surname $Surname -Department $Department -JobTitle $JobTitle -MailNickname $MailNickname -PasswordProfile $passwordProfile -ErrorAction Stop | Out-Null
        [pscustomobject]@{ UserPrincipalName = $UserPrincipalName; Action = 'Created' }
    }
    return
}

$updates = @{}
if ($existingUser.DisplayName -ne $DisplayName) { $updates['DisplayName'] = $DisplayName }
if ($GivenName -and $existingUser.GivenName -ne $GivenName) { $updates['GivenName'] = $GivenName }
if ($Surname -and $existingUser.Surname -ne $Surname) { $updates['Surname'] = $Surname }
if ($Department -and $existingUser.Department -ne $Department) { $updates['Department'] = $Department }
if ($JobTitle -and $existingUser.JobTitle -ne $JobTitle) { $updates['JobTitle'] = $JobTitle }
if ($existingUser.MailNickname -ne $MailNickname) { $updates['MailNickname'] = $MailNickname }

if ($updates.Count -eq 0) {
    Write-Verbose "User '$UserPrincipalName' already matches requested attributes."
    [pscustomobject]@{ UserPrincipalName = $UserPrincipalName; Action = 'NoChange' }
    return
}

if ($PSCmdlet.ShouldProcess($UserPrincipalName, 'Update Microsoft Entra user properties')) {
    Write-Verbose "Updating user '$UserPrincipalName' with changes: $($updates.Keys -join ', ')"
    Update-MgUser -UserId $existingUser.Id -BodyParameter $updates -ErrorAction Stop
    [pscustomobject]@{ UserPrincipalName = $UserPrincipalName; Action = 'Updated'; UpdatedProperties = $updates.Keys }
}
