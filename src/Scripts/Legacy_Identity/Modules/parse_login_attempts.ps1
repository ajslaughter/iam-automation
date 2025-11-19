# parse_login_attempts.ps1

param (
    [string]$LogName = "Security",
    [int]$MaxEvents = 100
)

try {
    $events = Get-WinEvent -LogName $LogName -MaxEvents $MaxEvents | Where-Object {
        $_.Id -eq 4624 -or $_.Id -eq 4625
    }

    foreach ($event in $events) {
        $type = if ($event.Id -eq 4624) { "SUCCESS" } else { "FAILURE" }
        $details = [xml]$event.ToXml()
        $user = $details.Event.EventData.Data | Where-Object {$_.Name -eq "TargetUserName"} | Select-Object -ExpandProperty '#text'
        $ip = $details.Event.EventData.Data | Where-Object {$_.Name -eq "IpAddress"} | Select-Object -ExpandProperty '#text'

        Write-Host "$type login - User: $user | IP: $ip | Time: $($event.TimeCreated)"
    }
}
catch {
    Write-Host "Error parsing login attempts: $_"
}
