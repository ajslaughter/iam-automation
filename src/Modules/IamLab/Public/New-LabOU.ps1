function New-LabOU {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter()]
        [string]$LogPath
    )

    try {
        Ensure-Module -Name 'ActiveDirectory'

        $ouDistinguishedName = "OU=$Name,$Path"
        Write-Verbose "Checking for existing OU '$ouDistinguishedName'."
        $existing = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouDistinguishedName'" -ErrorAction Stop
        if ($existing -is [System.Collections.IEnumerable] -and $existing -isnot [string]) {
            $existing = $existing | Select-Object -First 1
        }

        if ($existing) {
            if (-not $existing.ProtectedFromAccidentalDeletion) {
                if ($PSCmdlet.ShouldProcess($ouDistinguishedName, 'Enable protection from accidental deletion')) {
                    Set-ADOrganizationalUnit -Identity $existing -ProtectedFromAccidentalDeletion $true -ErrorAction Stop
                    Write-LabLog -Level 'INFO' -Message "Updated protection on OU '$ouDistinguishedName'." -LogPath $LogPath
                }
            }
            else {
                Write-Verbose "OU '$ouDistinguishedName' already exists with required settings."
            }
            return $existing
        }
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        Write-Verbose "OU '$ouDistinguishedName' not found. Will create."
    }
    catch {
        $message = "Failed to query OU '$Name'. $_"
        Write-LabLog -Level 'ERROR' -Message $message -LogPath $LogPath
        throw $message
    }

    if ($PSCmdlet.ShouldProcess($ouDistinguishedName, 'Create organizational unit')) {
        try {
            New-ADOrganizationalUnit -Name $Name -Path $Path -ProtectedFromAccidentalDeletion $true -ErrorAction Stop | Out-Null
            $message = "Created OU '$ouDistinguishedName'."
            Write-LabLog -Level 'INFO' -Message $message -LogPath $LogPath
            Write-Information -MessageData $message
            return Get-ADOrganizationalUnit -Identity $ouDistinguishedName -ErrorAction Stop
        }
        catch {
            $message = "Failed to create OU '$ouDistinguishedName'. $_"
            Write-LabLog -Level 'ERROR' -Message $message -LogPath $LogPath
            throw $message
        }
    }
}
