function New-LabUser {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$GivenName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Surname,

        [Parameter(Mandatory)]
        [ValidatePattern('^[A-Za-z0-9_\.-]{1,20}$')]
        [string]$SamAccountName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OU,

        [Parameter(Mandatory)]
        [System.Security.SecureString]$TempPassword,

        [Parameter()]
        [string[]]$AddToGroups,

        [Parameter()]
        [ValidatePattern('^.+@.+\..+$')]
        [string]$Email,

        [Parameter()]
        [string]$Title,

        [Parameter()]
        [string]$Department,

        [Parameter()]
        [switch]$ResetPassword,

        [Parameter()]
        [string]$LogPath
    )

    $ouDN = Resolve-OU -Name $OU
    $displayName = "$GivenName $Surname"
    $userPrincipalName = "$SamAccountName@$(Get-LabDomainFqdn)"

    try {
        Ensure-Module -Name 'ActiveDirectory'
    }
    catch {
        $message = "ActiveDirectory module unavailable. $_"
        Write-LabLog -Level 'ERROR' -Message $message -LogPath $LogPath
        throw $message
    }

    $user = $null
    $currentGroups = @()
    try {
        $user = Get-ADUser -Identity $SamAccountName -Properties GivenName,Surname,DisplayName,EmailAddress,Title,Department,Enabled,PasswordLastSet,UserPrincipalName -ErrorAction Stop
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        Write-Verbose "User '$SamAccountName' not found. Will create."
    }
    catch {
        $message = "Failed to query user '$SamAccountName'. $_"
        Write-LabLog -Level 'ERROR' -Message $message -LogPath $LogPath
        throw $message
    }

    if ($user) {
        try {
            $currentGroups = Get-ADPrincipalGroupMembership -Identity $user -ErrorAction Stop | ForEach-Object {
                if ($_.SamAccountName) { $_.SamAccountName } else { $_.Name }
            }
            $currentGroups = @($currentGroups)
        }
        catch {
            Write-Verbose "Unable to fetch existing group memberships for '$SamAccountName'. $_"
            $currentGroups = @()
        }

        $changes = @{}
        if ($user.GivenName -ne $GivenName) { $changes['GivenName'] = $GivenName }
        if ($user.Surname -ne $Surname) { $changes['Surname'] = $Surname }
        if ($user.DisplayName -ne $displayName) { $changes['DisplayName'] = $displayName }
        if ($user.UserPrincipalName -ne $userPrincipalName) { $changes['UserPrincipalName'] = $userPrincipalName }
        if ($Email -and $user.EmailAddress -ne $Email) { $changes['EmailAddress'] = $Email }
        if ($Title -and $user.Title -ne $Title) { $changes['Title'] = $Title }
        if ($Department -and $user.Department -ne $Department) { $changes['Department'] = $Department }

        if ($changes.Count -gt 0) {
            if ($PSCmdlet.ShouldProcess($SamAccountName, "Update user properties: $($changes.Keys -join ', ')") ) {
                try {
                    Set-ADUser @changes -Identity $user -ErrorAction Stop
                    $message = "Updated user '$SamAccountName' ($($changes.Keys -join ', '))."
                    Write-LabLog -Level 'INFO' -Message $message -LogPath $LogPath
                    Write-Information -MessageData $message
                }
                catch {
                    $message = "Failed to update user '$SamAccountName'. $_"
                    Write-LabLog -Level 'ERROR' -Message $message -LogPath $LogPath
                    throw $message
                }
            }
        }
        else {
            Write-Verbose "User '$SamAccountName' already compliant."
        }

        if (-not $user.Enabled) {
            if ($PSCmdlet.ShouldProcess($SamAccountName, 'Enable disabled account')) {
                try {
                    Enable-ADAccount -Identity $user -ErrorAction Stop
                    $message = "Enabled user '$SamAccountName'."
                    Write-LabLog -Level 'INFO' -Message $message -LogPath $LogPath
                }
                catch {
                    $message = "Failed to enable user '$SamAccountName'. $_"
                    Write-LabLog -Level 'ERROR' -Message $message -LogPath $LogPath
                    throw $message
                }
            }
        }

        if ($ResetPassword -or -not $user.PasswordLastSet) {
            if ($PSCmdlet.ShouldProcess($SamAccountName, 'Reset user password')) {
                try {
                    Set-ADAccountPassword -Identity $user -NewPassword $TempPassword -Reset -ErrorAction Stop
                    Set-ADUser -Identity $user -ChangePasswordAtLogon $true -ErrorAction Stop
                    $message = "Reset password for '$SamAccountName'."
                    Write-LabLog -Level 'INFO' -Message $message -LogPath $LogPath
                }
                catch {
                    $message = "Failed to reset password for '$SamAccountName'. $_"
                    Write-LabLog -Level 'ERROR' -Message $message -LogPath $LogPath
                    throw $message
                }
            }
        }
    }
    else {
        if ($PSCmdlet.ShouldProcess($SamAccountName, 'Create Active Directory user')) {
            try {
                $params = @{
                    Name                  = $displayName
                    SamAccountName        = $SamAccountName
                    GivenName             = $GivenName
                    Surname               = $Surname
                    DisplayName           = $displayName
                    Enabled               = $true
                    Path                  = $ouDN
                    AccountPassword       = $TempPassword
                    ChangePasswordAtLogon = $true
                    UserPrincipalName     = $userPrincipalName
                    ErrorAction           = 'Stop'
                }
                if ($Email) { $params['EmailAddress'] = $Email }
                if ($Title) { $params['Title'] = $Title }
                if ($Department) { $params['Department'] = $Department }
                New-ADUser @params
                $message = "Created user '$SamAccountName' in '$ouDN'."
                Write-LabLog -Level 'INFO' -Message $message -LogPath $LogPath
                Write-Information -MessageData $message
                $currentGroups = @()
            }
            catch {
                $message = "Failed to create user '$SamAccountName'. $_"
                Write-LabLog -Level 'ERROR' -Message $message -LogPath $LogPath
                throw $message
            }
        }
    }

    if ($AddToGroups) {
        foreach ($group in $AddToGroups) {
            if ([string]::IsNullOrWhiteSpace($group)) { continue }
            if ($currentGroups -and ($currentGroups -contains $group)) {
                Write-Verbose "User '$SamAccountName' is already a member of '$group'."
                continue
            }
            try {
                $groupParams = @{
                    SamAccountName = $SamAccountName
                    Group          = $group
                    LogPath        = $LogPath
                    ErrorAction    = 'Stop'
                }
                if ($PSBoundParameters.ContainsKey('WhatIf')) { $groupParams['WhatIf'] = $true }
                if ($PSBoundParameters.ContainsKey('Confirm')) { $groupParams['Confirm'] = $PSBoundParameters['Confirm'] }
                Add-LabUserToGroup @groupParams
                $currentGroups += $group
            }
            catch {
                $message = "Failed to add '$SamAccountName' to group '$group'. $_"
                Write-LabLog -Level 'ERROR' -Message $message -LogPath $LogPath
                throw $message
            }
        }
    }

    return Get-ADUser -Identity $SamAccountName -Properties * -ErrorAction Stop
}
