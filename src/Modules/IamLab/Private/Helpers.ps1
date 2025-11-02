Set-StrictMode -Version Latest

$script:LabConfigCache = $null

function Get-LabConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path
    )

    if (-not $Path) {
        if (-not $script:RepositoryRoot) {
            throw "Repository root is not initialized. Ensure the module psm1 sets `$script:RepositoryRoot`."
        }
        $Path = Join-Path -Path $script:RepositoryRoot -ChildPath 'config/IamLab.config.json'
    }

    if ($script:LabConfigCache -and $script:LabConfigCache.__SourcePath -eq (Resolve-Path -Path $Path -ErrorAction Stop)) {
        return $script:LabConfigCache
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Configuration file not found at '$Path'."
    }

    try {
        $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
        $config = $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Failed to read configuration file '$Path'. $_"
    }

    $requiredKeys = 'DomainDN','CompanyOUDN','Departments','DefaultPasswordSecretName','LoggingRoot'
    foreach ($key in $requiredKeys) {
        if (-not ($config.PSObject.Properties.Name -contains $key)) {
            throw "Configuration is missing required key '$key'."
        }
    }

    if (-not ($config.Departments -is [System.Collections.IEnumerable])) {
        throw "Configuration value 'Departments' must be an array."
    }

    $config | Add-Member -NotePropertyName '__SourcePath' -NotePropertyValue (Resolve-Path -Path $Path) -Force
    $script:LabConfigCache = $config
    return $config
}

function Write-LabLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('INFO','WARN','ERROR')]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [string]$LogPath
    )

    $config = Get-LabConfig

    if (-not $LogPath) {
        $logRoot = if ($config.LoggingRoot) { $config.LoggingRoot } else { '.\logs' }
    }
    else {
        $logRoot = $LogPath
    }

    $dateSegment = (Get-Date -Format 'yyyy-MM-dd')
    $fullLogDir = Join-Path -Path $logRoot -ChildPath $dateSegment

    if (-not (Test-Path -LiteralPath $fullLogDir)) {
        New-Item -ItemType Directory -Path $fullLogDir -Force | Out-Null
    }

    $logFile = Join-Path -Path $fullLogDir -ChildPath 'IamLab.log'
    $timestamp = (Get-Date).ToString('s')
    $entry = "[$timestamp] [$Level] $Message"

    try {
        Add-Content -LiteralPath $logFile -Value $entry -Encoding UTF8
    }
    catch {
        Write-Verbose "Failed to write to log file '$logFile'. $_"
    }
}

function Resolve-OU {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $config = Get-LabConfig
    if ($Name -match '=') {
        return $Name
    }

    $companyOU = $config.CompanyOUDN
    if (-not $companyOU) {
        throw "CompanyOUDN is not defined in configuration."
    }

    return "OU=$Name,$companyOU"
}

function Ensure-Module {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    if (-not (Get-Module -Name $Name -ListAvailable)) {
        throw "Required module '$Name' is not available. Install RSAT or the appropriate feature."
    }

    if (-not (Get-Module -Name $Name)) {
        Import-Module -Name $Name -ErrorAction Stop
    }
}

function Get-DefaultPassword {
    [CmdletBinding()]
    param()

    $placeholder = 'P@ssw0rd!'
    return ConvertTo-SecureString -String $placeholder -AsPlainText -Force
}

function Get-LabDomainFqdn {
    [CmdletBinding()]
    param()

    $config = Get-LabConfig
    $parts = $config.DomainDN -split ',' | ForEach-Object { $_ -replace '^DC=', '' }
    return ($parts -join '.')
}
