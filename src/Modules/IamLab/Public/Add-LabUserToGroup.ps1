function Add-LabUserToGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SamAccountName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Group,

        [Parameter()]
        [string]$LogPath
    )

    try {
        Ensure-Module -Name 'ActiveDirectory'
        $user = Get-ADUser -Identity $SamAccountName -ErrorAction Stop
        $adGroup = Get-ADGroup -Identity $Group -ErrorAction Stop
    }
    catch {
        $message = "Failed to resolve user '$SamAccountName' or group '$Group'. $_"
        Write-LabLog -Level 'ERROR' -Message $message -LogPath $LogPath
        throw $message
    }

    try {
        $memberships = Get-ADPrincipalGroupMembership -Identity $user -ErrorAction Stop
        if ($memberships.DistinguishedName -contains $adGroup.DistinguishedName) {
            Write-Verbose "User '$SamAccountName' is already a member of '$($adGroup.Name)'."
            return
        }
    }
    catch {
        Write-Verbose "Unable to enumerate current memberships for '$SamAccountName'. Proceeding with add. $_"
    }

    if ($PSCmdlet.ShouldProcess("$SamAccountName -> $($adGroup.Name)", 'Add user to group')) {
        try {
            Add-ADGroupMember -Identity $adGroup -Members $user -ErrorAction Stop
            $message = "Added '$SamAccountName' to group '$($adGroup.Name)'."
            Write-LabLog -Level 'INFO' -Message $message -LogPath $LogPath
            Write-Information -MessageData $message
        }
        catch {
            $message = "Failed to add '$SamAccountName' to group '$($adGroup.Name)'. $_"
            Write-LabLog -Level 'ERROR' -Message $message -LogPath $LogPath
            throw $message
        }
    }
}
