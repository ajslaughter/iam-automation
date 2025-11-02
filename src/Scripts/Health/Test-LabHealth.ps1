[CmdletBinding()]
param(
    [Parameter()]
    [string[]]$DomainControllers
)

#requires -Modules ActiveDirectory, DnsServer

function Add-Result {
    param(
        [ref]$Collection,
        [string]$Test,
        [string]$Target,
        [string]$Status,
        [string]$Details
    )

    $Collection.Value += [pscustomobject]@{
        Test    = $Test
        Target  = $Target
        Status  = $Status
        Details = $Details
    }
}

$results = @()

try {
    if (-not $DomainControllers) {
        $DomainControllers = (Get-ADDomainController -Filter * -ErrorAction Stop).HostName
    }
} catch {
    throw "Unable to enumerate domain controllers. $_"
}

foreach ($dc in $DomainControllers) {
    try {
        $metadata = Get-ADReplicationPartnerMetadata -Target $dc -ErrorAction Stop
        if ($metadata | Where-Object { $_.LastSyncResult -ne 0 }) {
            Add-Result -Collection ([ref]$results) -Test 'Replication' -Target $dc -Status 'Failed' -Details 'One or more partners reporting replication failures.'
        } else {
            Add-Result -Collection ([ref]$results) -Test 'Replication' -Target $dc -Status 'Passed' -Details 'Replication healthy.'
        }
    } catch {
        Add-Result -Collection ([ref]$results) -Test 'Replication' -Target $dc -Status 'Failed' -Details $_.Exception.Message
    }

    try {
        $services = Get-Service -ComputerName $dc -Name 'NTDS', 'DNS', 'Netlogon', 'DFS Replication' -ErrorAction Stop
        $stopped = $services | Where-Object { $_.Status -ne 'Running' }
        if ($stopped) {
            $detail = 'Services not running: ' + ($stopped.Name -join ', ')
            Add-Result -Collection ([ref]$results) -Test 'Core Services' -Target $dc -Status 'Failed' -Details $detail
        } else {
            Add-Result -Collection ([ref]$results) -Test 'Core Services' -Target $dc -Status 'Passed' -Details 'All critical services running.'
        }
    } catch {
        Add-Result -Collection ([ref]$results) -Test 'Core Services' -Target $dc -Status 'Failed' -Details $_.Exception.Message
    }

    $sysvolPath = "\\$dc\SYSVOL"
    $netlogonPath = "\\$dc\NETLOGON"
    $sysvolOk = Test-Path -Path $sysvolPath
    $netlogonOk = Test-Path -Path $netlogonPath
    if ($sysvolOk -and $netlogonOk) {
        Add-Result -Collection ([ref]$results) -Test 'SYSVOL/Netlogon' -Target $dc -Status 'Passed' -Details 'SYSVOL and Netlogon shares accessible.'
    } else {
        $missing = @()
        if (-not $sysvolOk) { $missing += 'SYSVOL' }
        if (-not $netlogonOk) { $missing += 'NETLOGON' }
        Add-Result -Collection ([ref]$results) -Test 'SYSVOL/Netlogon' -Target $dc -Status 'Failed' -Details ('Missing shares: ' + ($missing -join ', '))
    }

    try {
        $forwarders = Get-DnsServerForwarder -ComputerName $dc -ErrorAction Stop
        if ($forwarders) {
            $detail = 'Forwarders: ' + (($forwarders.IPAddress.IPAddressToString) -join ', ')
            Add-Result -Collection ([ref]$results) -Test 'DNS Forwarders' -Target $dc -Status 'Passed' -Details $detail
        } else {
            Add-Result -Collection ([ref]$results) -Test 'DNS Forwarders' -Target $dc -Status 'Failed' -Details 'No forwarders configured.'
        }
    } catch {
        Add-Result -Collection ([ref]$results) -Test 'DNS Forwarders' -Target $dc -Status 'Failed' -Details $_.Exception.Message
    }

    $monitorOutput = & w32tm /monitor /computers:$dc 2>&1
    if ($LASTEXITCODE -eq 0 -and ($monitorOutput -notmatch 'error')) {
        Add-Result -Collection ([ref]$results) -Test 'Time Sync' -Target $dc -Status 'Passed' -Details ($monitorOutput -join ' ')
    } else {
        Add-Result -Collection ([ref]$results) -Test 'Time Sync' -Target $dc -Status 'Failed' -Details ($monitorOutput -join ' ')
    }
}

$results | Format-Table -AutoSize | Out-String | Write-Host

if ($results.Status -contains 'Failed') {
    exit 1
}
