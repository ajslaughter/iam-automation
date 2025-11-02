function Test-LabAdAvailable {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter()]
        [string]$LogPath
    )

    try {
        if (-not $PSCmdlet.ShouldProcess('Active Directory', 'Validate connectivity and module availability')) {
            return $false
        }

        Write-Verbose 'Ensuring ActiveDirectory module is available.'
        Ensure-Module -Name 'ActiveDirectory'

        Write-Verbose 'Querying Active Directory domain information.'
        $domain = Get-ADDomain -ErrorAction Stop
        $message = "Active Directory available. Domain: $($domain.DistinguishedName)"
        Write-LabLog -Level 'INFO' -Message $message -LogPath $LogPath
        Write-Information -MessageData $message
        return $true
    }
    catch {
        $errorMessage = "Unable to connect to Active Directory. $_"
        Write-LabLog -Level 'ERROR' -Message $errorMessage -LogPath $LogPath
        Write-Error -Message $errorMessage
        return $false
    }
}
