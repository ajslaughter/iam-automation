function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$Level] $Message"

    # Ensure logs folder exists
    $logDir = ".\logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir | Out-Null
    }

    # Write to console
    Write-Host $logMessage

    # Append to log file
    $logFile = "$logDir\iam-automation.log"
    $logMessage | Out-File -FilePath $logFile -Append -Encoding utf8
}
