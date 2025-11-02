[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory, ParameterSetName = 'List')]
    [string[]]$ComputerName,

    [Parameter(Mandatory, ParameterSetName = 'Csv')]
    [string]$InputCsv,

    [Parameter()]
    [switch]$Install,

    [Parameter()]
    [string]$Schedule,

    [Parameter()]
    [switch]$RebootIfNeeded,

    [Parameter()]
    [string]$ReportPath
)

#requires -Modules PSWindowsUpdate

function Get-TargetComputers {
    param(
        [System.Management.Automation.PSBoundParametersDictionary]$BoundParameters,
        [string]$ParameterSetName
    )

    switch ($ParameterSetName) {
        'Csv' {
            Write-Verbose "Loading computer list from '$($BoundParameters['InputCsv'])'."
            return (Import-Csv -Path $BoundParameters['InputCsv']).ComputerName | Where-Object { $_ } | Select-Object -Unique
        }
        default {
            return $BoundParameters['ComputerName'] | Where-Object { $_ } | Select-Object -Unique
        }
    }
}

function Get-NextSchedule {
    param([string]$Expression)

    if (-not $Expression) { return $null }

    $parts = $Expression.Split(' ', 2, [System.StringSplitOptions]::RemoveEmptyEntries)
    if ($parts.Count -lt 2) {
        throw "Schedule format should be '<DayOfWeek> <HH:MM>'."
    }

    $day = $parts[0]
    $timePart = $parts[1]

    try {
        $targetDay = [System.Enum]::Parse([System.DayOfWeek], $day, $true)
    } catch {
        throw "Unrecognized day of week '$day'."
    }

    try {
        $targetTime = [DateTime]::ParseExact($timePart, 'HH:mm', $null)
    } catch {
        throw "Unable to parse time portion '$timePart'."
    }
    $now = Get-Date
    $candidate = Get-Date -Hour $targetTime.Hour -Minute $targetTime.Minute -Second 0 -Millisecond 0
    while ($candidate.DayOfWeek -ne $targetDay -or $candidate -le $now) {
        $candidate = $candidate.AddDays(1)
        $candidate = Get-Date $candidate -Hour $targetTime.Hour -Minute $targetTime.Minute -Second 0 -Millisecond 0
    }

    return $candidate
}

$targets = Get-TargetComputers -BoundParameters $PSBoundParameters -ParameterSetName $PSCmdlet.ParameterSetName
if (-not $targets) {
    throw 'No target computers supplied.'
}

if (-not $ReportPath) {
    $repoRoot = Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..')
    $ReportPath = Join-Path -Path $repoRoot -ChildPath 'patch-report.csv'
}

$scheduledTime = Get-NextSchedule -Expression $Schedule
if ($scheduledTime) {
    Write-Verbose "Planned patch window: $scheduledTime"
}

$results = @()
foreach ($computer in $targets) {
    $action = $Install.IsPresent ? 'Install updates via PSWindowsUpdate' : 'Scan for available updates'
    if ($PSCmdlet.ShouldProcess($computer, $action)) {
        Write-Verbose "Processing computer '$computer'."
        try {
            $scriptBlock = {
                param($DoInstall,$Reboot)
                Import-Module PSWindowsUpdate | Out-Null
                if ($DoInstall) {
                    $installResult = Install-WindowsUpdate -AcceptAll -IgnoreReboot:(!$Reboot) -Confirm:$false -ErrorAction Stop
                    return $installResult
                } else {
                    $scanResult = Get-WindowsUpdate -MicrosoftUpdate -ErrorAction Stop
                    return $scanResult
                }
            }

            $invokeParams = @{ ComputerName = $computer; ScriptBlock = $scriptBlock; ArgumentList = @($Install.IsPresent, $RebootIfNeeded.IsPresent); ErrorAction = 'Stop' }
            $sessionResults = Invoke-Command @invokeParams

            if ($Install) {
                $kbList = ($sessionResults | Where-Object { $_.KB -and $_.Result -eq 'Succeeded' }).KB
                $needsReboot = [bool]($sessionResults | Where-Object { $_.RebootRequired })
                $results += [pscustomobject]@{
                    Computer      = $computer
                    InstalledKBs  = ($kbList -join '; ')
                    Reboot        = $needsReboot -or $RebootIfNeeded.IsPresent
                    Result        = if ($sessionResults -and $sessionResults[0].Result) { $sessionResults[0].Result } elseif ($sessionResults) { 'Completed' } else { 'No updates' }
                }
            } else {
                $availableKbs = ($sessionResults | Select-Object -ExpandProperty KB -ErrorAction SilentlyContinue) -join '; '
                $results += [pscustomobject]@{
                    Computer      = $computer
                    InstalledKBs  = $availableKbs
                    Reboot        = $false
                    Result        = 'Scan complete'
                }
            }

            if ($Install -and $RebootIfNeeded -and ($results[-1].Reboot)) {
                Write-Verbose "Reboot requested for '$computer'."
                Restart-Computer -ComputerName $computer -Force -ErrorAction SilentlyContinue
            }
        } catch {
            Write-Warning "Failed to patch '$computer': $_"
            $results += [pscustomobject]@{
                Computer      = $computer
                InstalledKBs  = $null
                Reboot        = $false
                Result        = "Failed: $($_.Exception.Message)"
            }
        }
    } else {
        $results += [pscustomobject]@{
            Computer      = $computer
            InstalledKBs  = $null
            Reboot        = $false
            Result        = if ($Install) { 'Planned install (WhatIf)' } else { 'Planned scan (WhatIf)' }
        }
    }
}

Write-Verbose "Writing patch report to '$ReportPath'."
$results | Export-Csv -Path $ReportPath -NoTypeInformation
Write-Output $results
