function New-LabSecurityGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OU,

        [Parameter(Mandatory)]
        [ValidateSet('Global', 'DomainLocal', 'Universal')]
        [string]$Scope,

        [Parameter()]
        [string]$Description,

        [Parameter()]
        [string]$LogPath
    )

    try {
        Ensure-Module -Name 'ActiveDirectory'

        $ouDN = Resolve-OU -Name $OU
        $groupIdentity = "CN=$Name,$ouDN"
        Write-Verbose "Checking for existing group '$groupIdentity'."
        $existing = Get-ADGroup -Identity $groupIdentity -ErrorAction Stop
        if ($existing -is [System.Collections.IEnumerable] -and $existing -isnot [string]) {
            $existing = $existing | Select-Object -First 1
        }

        $changes = @()
        if ($Description -and $existing.Description -ne $Description) {
            $changes += 'description'
        }
        if ($existing.GroupScope -ne $Scope) {
            $changes += 'scope'
        }

        if ($changes.Count -gt 0) {
            if ($PSCmdlet.ShouldProcess($groupIdentity, "Update group $($changes -join ', ')") ) {
                $params = @{ Identity = $existing; ErrorAction = 'Stop' }
                if ($changes -contains 'description') { $params['Description'] = $Description }
                if ($changes -contains 'scope') { $params['GroupScope'] = $Scope }
                Set-ADGroup @params
                $message = "Updated group '$groupIdentity' ($($changes -join ', '))."
                Write-LabLog -Level 'INFO' -Message $message -LogPath $LogPath
                Write-Information -MessageData $message
            }
        }
        else {
            Write-Verbose "Group '$groupIdentity' already compliant."
        }

        return $existing
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        Write-Verbose "Group '$Name' not found. Will create in '$ouDN'."
    }
    catch {
        $message = "Failed to query group '$Name'. $_"
        Write-LabLog -Level 'ERROR' -Message $message -LogPath $LogPath
        throw $message
    }

    if ($PSCmdlet.ShouldProcess($groupIdentity, 'Create security group')) {
        try {
            $params = @{
                Name         = $Name
                Path         = $ouDN
                GroupScope   = $Scope
                GroupCategory= 'Security'
                ErrorAction  = 'Stop'
            }
            if ($Description) { $params['Description'] = $Description }
            New-ADGroup @params | Out-Null
            $message = "Created security group '$groupIdentity'."
            Write-LabLog -Level 'INFO' -Message $message -LogPath $LogPath
            Write-Information -MessageData $message
            return Get-ADGroup -Identity $groupIdentity -ErrorAction Stop
        }
        catch {
            $message = "Failed to create group '$groupIdentity'. $_"
            Write-LabLog -Level 'ERROR' -Message $message -LogPath $LogPath
            throw $message
        }
    }
}
