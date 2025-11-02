function Disable-LabUser {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SamAccountName,

        [Parameter()]
        [string]$LogPath
    )

    try {
        Ensure-Module -Name 'ActiveDirectory'
        $user = Get-ADUser -Identity $SamAccountName -Properties Enabled,SmartcardLogonRequired -ErrorAction Stop
    }
    catch {
        $message = "Failed to locate user '$SamAccountName'. $_"
        Write-LabLog -Level 'ERROR' -Message $message -LogPath $LogPath
        throw $message
    }

    if (-not $user.Enabled) {
        Write-Verbose "User '$SamAccountName' already disabled."
    }

    if ($PSCmdlet.ShouldProcess($SamAccountName, 'Disable Active Directory account')) {
        try {
            if ($user.SmartcardLogonRequired) {
                Set-ADUser -Identity $user -SmartcardLogonRequired $false -ErrorAction Stop
            }
            Disable-ADAccount -Identity $user -ErrorAction Stop
            $message = "Disabled user '$SamAccountName'."
            Write-LabLog -Level 'WARN' -Message $message -LogPath $LogPath
            Write-Information -MessageData $message
        }
        catch {
            $message = "Failed to disable user '$SamAccountName'. $_"
            Write-LabLog -Level 'ERROR' -Message $message -LogPath $LogPath
            throw $message
        }
    }
}
