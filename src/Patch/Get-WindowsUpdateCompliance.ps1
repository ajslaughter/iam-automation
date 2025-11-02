[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [string[]]$ComputerName = @('localhost'),

    [Parameter()]
    [string]$OutputPath = './out/patch',

    [Parameter()]
    [switch]$IncludeDrivers,

    [Parameter()]
    [ValidateRange(1, 128)]
    [int]$ThrottleLimit = 8,

    [Parameter()]
    [switch]$AsJsonOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-OutputDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path) {
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        if (-not $item.PSIsContainer) {
            throw "OutputPath '$Path' exists and is not a directory."
        }
    }
    else {
        Write-Verbose "Creating output directory at '$Path'."
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }

    return (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
}

function Initialize-PSWindowsUpdateModule {
    [CmdletBinding()]
    param()

    $moduleName = 'PSWindowsUpdate'

    $available = Get-Module -Name $moduleName -ListAvailable
    if (-not $available) {
        Write-Verbose "Downloading module '$moduleName' for current session."
        $tempModuleRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath $moduleName
        if (-not (Test-Path -LiteralPath $tempModuleRoot)) {
            New-Item -ItemType Directory -Path $tempModuleRoot -Force | Out-Null
        }

        Save-Module -Name $moduleName -Repository PSGallery -Path $tempModuleRoot -Force
        $moduleVersionPath = Get-ChildItem -Path (Join-Path -Path $tempModuleRoot -ChildPath $moduleName) -Directory |
            Sort-Object -Property Name -Descending |
            Select-Object -First 1

        if (-not $moduleVersionPath) {
            throw "Unable to locate saved module '$moduleName' after download."
        }

        Import-Module -Name $moduleVersionPath.FullName -ErrorAction Stop
        return
    }

    if (-not (Get-Module -Name $moduleName)) {
        Import-Module -Name $moduleName -ErrorAction Stop
    }
}

Initialize-PSWindowsUpdateModule

$timestamp = Get-Date
$timestampTag = $timestamp.ToString('yyyyMMdd-HHmmss')
$timestampIso = $timestamp.ToString('o')

$resolvedOutputPath = Resolve-OutputDirectory -Path $OutputPath

$results = @()

Write-Verbose "Using a throttle limit of $ThrottleLimit for sequential processing."

foreach ($computer in $ComputerName) {
    Write-Verbose "Collecting Windows Update information from '$computer'."

    $entry = [ordered]@{
        ComputerName   = $computer
        Timestamp      = $timestampIso
        Updates        = @()
        LastInstall    = $null
        RebootRequired = $null
        Errors         = @()
    }

    $hostErrors = @()

    try {
        $updateType = if ($IncludeDrivers.IsPresent) { 'SoftwareAndDriver' } else { 'Software' }

        $wuListParams = [ordered]@{
            ComputerName = $computer
            IsInstalled  = $false
            UpdateType   = $updateType
            ErrorAction  = 'Stop'
        }

        $updates = Get-WUList @wuListParams

        if ($updates) {
            $entry.Updates = @(
                foreach ($update in $updates) {
                    [pscustomobject][ordered]@{
                        KB       = $update.KB
                        Title    = $update.Title
                        Severity = $update.MsrcSeverity
                        Size     = $update.Size
                        Category = $update.Categories
                    }
                }
            )
        }

        try {
            $history = Get-WUHistory -ComputerName $computer -Last 1 -ErrorAction Stop
            if ($history) {
                $entry.LastInstall = $history[0].Date
            }
        }
        catch {
            $hostErrors += "Failed to retrieve update history: $($_.Exception.Message)"
            Write-Information "[$computer] Failed to retrieve update history: $($_.Exception.Message)"
        }

        try {
            $reboot = Get-WURebootStatus -ComputerName $computer -ErrorAction Stop
            if ($null -ne $reboot -and $reboot.PSObject.Properties.Match('RebootRequired').Count -gt 0) {
                $entry.RebootRequired = [bool]$reboot.RebootRequired
            }
        }
        catch {
            $hostErrors += "Failed to determine reboot status: $($_.Exception.Message)"
            Write-Information "[$computer] Failed to determine reboot status: $($_.Exception.Message)"
        }
    }
    catch {
        $message = $_.Exception.Message
        $hostErrors += $message
        Write-Information "[$computer] Error collecting update information: $message"
    }

    if ($hostErrors.Count -gt 0) {
        $entry.Errors = $hostErrors
    }

    $results += [pscustomobject]$entry
}

$jsonOutputPath = Join-Path -Path $resolvedOutputPath -ChildPath ("{0}-compliance.json" -f $timestampTag)

$json = $results | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($jsonOutputPath, $json, [System.Text.Encoding]::UTF8)

if (-not $AsJsonOnly.IsPresent) {
    $summary = $results | Select-Object -Property @(
        @{ Name = 'ComputerName'; Expression = { $_.ComputerName } },
        @{ Name = 'UpdateCount'; Expression = { $_.Updates.Count } },
        @{ Name = 'LastInstall'; Expression = { if ($_.LastInstall) { $_.LastInstall.ToString('u') } else { '' } } },
        @{ Name = 'RebootRequired'; Expression = {
                if ($null -eq $_.RebootRequired) { 'Unknown' }
                elseif ($_.RebootRequired) { 'Yes' }
                else { 'No' }
            }
        },
        @{ Name = 'Errors'; Expression = { ($_.Errors -join '; ') } }
    )

    $preContent = @(
        '<h1>Windows Update Compliance</h1>',
        "<p>Generated: $($timestamp.ToString('u'))</p>"
    ) -join [Environment]::NewLine

    $html = $summary | ConvertTo-Html -Title 'Windows Update Compliance' -PreContent $preContent
    $htmlOutputPath = Join-Path -Path $resolvedOutputPath -ChildPath ("{0}-compliance.html" -f $timestampTag)
    [System.IO.File]::WriteAllText($htmlOutputPath, $html, [System.Text.Encoding]::UTF8)
}

return $results
