[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [Alias('Target')]
    [string]$TargetOUDN,

    [Parameter()]
    [ValidateRange(1, 999)]
    [int]$LinkOrder = 1,

    [Parameter()]
    [switch]$Enforced,

    [Parameter()]
    [switch]$LinkEnabled
)

#requires -Modules GroupPolicy

$LinkEnabledValue = $PSBoundParameters.ContainsKey('LinkEnabled') ? $LinkEnabled.IsPresent : $true

try {
    $gpo = Get-GPO -Name $Name -ErrorAction Stop
} catch {
    throw "Unable to locate GPO '$Name'. $_"
}

$inheritance = Get-GPInheritance -Target $TargetOUDN -ErrorAction Stop
$link = $inheritance.GpoLinks | Where-Object { $_.DisplayName -eq $Name }

if (-not $link) {
    if ($PSCmdlet.ShouldProcess($TargetOUDN, "Link GPO '$Name'")) {
        Write-Verbose "Linking '$Name' to '$TargetOUDN' with order $LinkOrder (Enabled: $LinkEnabledValue, Enforced: $($Enforced.IsPresent))."
        New-GPLink -Name $Name -Target $TargetOUDN -LinkEnabled:$LinkEnabledValue -Order $LinkOrder -Enforced:$Enforced.IsPresent -ErrorAction Stop | Out-Null
    }
    return
}

Write-Verbose "Existing link for '$Name' found at '$TargetOUDN' (Order: $($link.Order), Enabled: $($link.Enabled), Enforced: $($link.Enforced))."

if ($link.Order -ne $LinkOrder) {
    if ($PSCmdlet.ShouldProcess($TargetOUDN, "Update link order for '$Name' to $LinkOrder")) {
        Write-Verbose "Adjusting link order from $($link.Order) to $LinkOrder."
        Set-GPLink -Name $Name -Target $TargetOUDN -Order $LinkOrder -ErrorAction Stop | Out-Null
    }
}

if ($link.Enforced -ne $Enforced.IsPresent) {
    if ($PSCmdlet.ShouldProcess($TargetOUDN, "Set enforced state for '$Name' to $($Enforced.IsPresent)")) {
        Write-Verbose "Updating enforced flag from $($link.Enforced) to $($Enforced.IsPresent)."
        Set-GPLink -Name $Name -Target $TargetOUDN -Enforced:$Enforced.IsPresent -ErrorAction Stop | Out-Null
    }
}

if ($link.Enabled -ne $LinkEnabledValue) {
    if ($PSCmdlet.ShouldProcess($TargetOUDN, "Set link enabled state for '$Name' to $LinkEnabledValue")) {
        Write-Verbose "Updating link enabled flag from $($link.Enabled) to $LinkEnabledValue."
        Set-GPLink -Name $Name -Target $TargetOUDN -LinkEnabled:$LinkEnabledValue -ErrorAction Stop | Out-Null
    }
}
