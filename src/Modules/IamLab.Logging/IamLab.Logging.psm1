function Write-IamLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('Information', 'Warning', 'Error', 'Verbose')]
        [string]$Level = 'Information',

        [Parameter()]
        [string]$LogFile
    )

    process {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $formattedMessage = "[$timestamp] [$Level] $Message"

        switch ($Level) {
            'Information' { Write-Host $formattedMessage -ForegroundColor Cyan }
            'Warning'     { Write-Warning $formattedMessage }
            'Error'       { Write-Error $formattedMessage }
            'Verbose'     { Write-Verbose $formattedMessage }
        }

        if ($LogFile) {
            Add-Content -Path $LogFile -Value $formattedMessage
        }
    }
}

Export-ModuleMember -Function Write-IamLog
