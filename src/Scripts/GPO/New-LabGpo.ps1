[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,

    [Parameter()]
    [string]$Comment,

    [Parameter()]
    [string]$Owner = 'Domain Admins'
)

#requires -Modules GroupPolicy

function Write-Change {
    param(
        [string]$Message
    )
    Write-Verbose $Message
}

try {
    $existing = Get-GPO -Name $Name -ErrorAction SilentlyContinue
} catch {
    throw "Failed to query GPO '$Name'. $_"
}

if (-not $existing) {
    if ($PSCmdlet.ShouldProcess($Name, 'Create new Group Policy Object')) {
        Write-Change "Creating new GPO '$Name'."
        $existing = New-GPO -Name $Name -Comment $Comment -ErrorAction Stop
        if ($Owner) {
            Write-Change "Setting owner of '$Name' to '$Owner'."
            Set-GPO -Guid $existing.Id -Owner $Owner -ErrorAction Stop | Out-Null
        }
    }
} else {
    Write-Change "Found existing GPO '$Name' (Id: $($existing.Id))."
}

if ($existing) {
    $refresh = $false

    if ($PSBoundParameters.ContainsKey('Comment') -and $existing.Description -ne $Comment) {
        if ($PSCmdlet.ShouldProcess($Name, "Update comment to '$Comment'")) {
            Write-Change "Updating comment for '$Name' from '$($existing.Description)' to '$Comment'."
            Set-GPO -Guid $existing.Id -Comment $Comment -ErrorAction Stop | Out-Null
            $refresh = $true
        }
    }

    if ($PSBoundParameters.ContainsKey('Owner') -and $Owner -and $existing.Owner -ne $Owner) {
        if ($PSCmdlet.ShouldProcess($Name, "Update owner to '$Owner'")) {
            Write-Change "Updating owner for '$Name' from '$($existing.Owner)' to '$Owner'."
            Set-GPO -Guid $existing.Id -Owner $Owner -ErrorAction Stop | Out-Null
            $refresh = $true
        }
    }

    if ($refresh) {
        $existing = Get-GPO -Name $Name -ErrorAction Stop
    }
}

return $existing
