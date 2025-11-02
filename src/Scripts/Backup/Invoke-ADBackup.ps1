[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [string[]]$ComputerName,

    [Parameter()]
    [string]$BackupTarget = 'C:\\Backups'
)

#requires -Modules ActiveDirectory

if (-not $ComputerName) {
    $ComputerName = (Get-ADDomainController -Filter * -ErrorAction Stop).HostName
}

$results = @()
foreach ($dc in $ComputerName) {
    if (-not $PSCmdlet.ShouldProcess($dc, 'Trigger system state backup')) {
        $results += [pscustomobject]@{
            Computer     = $dc
            BackupTarget = $BackupTarget
            LastSuccess  = $null
            Status       = 'Planned (WhatIf)'
        }
        continue
    }

    Write-Verbose "Ensuring backup directory '$BackupTarget' exists on '$dc'."
    $scriptBlock = {
        param($BackupTarget)
        if (-not (Test-Path -Path $BackupTarget)) {
            New-Item -Path $BackupTarget -ItemType Directory -Force | Out-Null
        }
        $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
        $logFile = Join-Path -Path $BackupTarget -ChildPath ("SystemState-$env:COMPUTERNAME-$timestamp.txt")
        $command = "wbadmin start systemstatebackup -backuptarget:\"$BackupTarget\" -quiet"
        $output = cmd.exe /c $command 2>&1
        $output | Out-File -FilePath $logFile -Encoding UTF8

        $lastSuccess = Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-Backup'; Id = 14 } -MaxEvents 1 -ErrorAction SilentlyContinue
        [pscustomobject]@{
            LogPath     = $logFile
            LastSuccess = if ($lastSuccess) { $lastSuccess.TimeCreated } else { $null }
            Output      = $output
        }
    }

    try {
        $result = Invoke-Command -ComputerName $dc -ScriptBlock $scriptBlock -ArgumentList $BackupTarget -ErrorAction Stop
        $status = if ($result.LastSuccess) { 'Completed' } else { 'Check logs' }
        $results += [pscustomobject]@{
            Computer     = $dc
            BackupTarget = $BackupTarget
            LastSuccess  = $result.LastSuccess
            Status       = $status
            LogPath      = $result.LogPath
        }
    } catch {
        Write-Warning "Backup failed on '$dc': $_"
        $results += [pscustomobject]@{
            Computer     = $dc
            BackupTarget = $BackupTarget
            LastSuccess  = $null
            Status       = "Failed: $($_.Exception.Message)"
        }
    }
}

$results
