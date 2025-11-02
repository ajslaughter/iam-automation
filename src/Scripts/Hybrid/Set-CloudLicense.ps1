[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)]
    [string]$UserPrincipalName,

    [Parameter(Mandatory)]
    [string]$LicenseDisplayName,

    [Parameter()]
    [string[]]$EnabledPlans
)

#requires -Modules Microsoft.Graph.Users, Microsoft.Graph.Identity.DirectoryManagement

if (-not (Get-IamLabFeatureFlag -Name 'HybridIdentity' -AsBoolean)) {
    Write-Warning 'Hybrid identity automation is disabled. Enable it in config/features.json before running cloud workflows.'
    return
}

Import-Module Microsoft.Graph.Users -ErrorAction Stop | Out-Null
Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction Stop | Out-Null

$user = Get-MgUser -UserId $UserPrincipalName -ErrorAction Stop
$skus = Get-MgSubscribedSku -All -ErrorAction Stop
$sku = $skus | Where-Object { $_.SkuPartNumber -eq $LicenseDisplayName -or $_.SkuId -eq $LicenseDisplayName -or $_.PrepaidUnits.Enabled -and $_.SkuPartNumber -eq $LicenseDisplayName }
if (-not $sku) {
    throw "Unable to locate subscribed SKU for '$LicenseDisplayName'."
}

$licenseDetails = Get-MgUserLicenseDetail -UserId $user.Id -ErrorAction Stop
$assigned = $licenseDetails | Where-Object { $_.SkuId -eq $sku.SkuId }

$servicePlans = $sku.ServicePlans
$enabledPlanIds = @()
if ($EnabledPlans) {
    foreach ($plan in $EnabledPlans) {
        $match = $servicePlans | Where-Object { $_.ServicePlanName -eq $plan -or $_.ServicePlanId -eq $plan }
        if (-not $match) {
            throw "Plan '$plan' is not part of SKU '$LicenseDisplayName'."
        }
        $enabledPlanIds += $match.ServicePlanId
    }
}

$disabledPlans = @()
if ($servicePlans) {
    foreach ($plan in $servicePlans) {
        if ($EnabledPlans -and $enabledPlanIds -contains $plan.ServicePlanId) { continue }
        if ($EnabledPlans) {
            $disabledPlans += $plan.ServicePlanId
        }
    }
}

if ($assigned) {
    $currentDisabled = @()
    foreach ($plan in $assigned.ServicePlans) {
        if ($plan.ProvisioningStatus -eq 'Disabled') {
            $currentDisabled += $plan.ServicePlanId
        }
    }

    $requiresUpdate = $false
    if ($EnabledPlans) {
        $requiresUpdate = -not (@($currentDisabled | Sort-Object) -ceq @($disabledPlans | Sort-Object))
    } else {
        $requiresUpdate = $false
    }

    if (-not $requiresUpdate) {
        Write-Verbose "License '$LicenseDisplayName' already assigned to '$UserPrincipalName'."
        [pscustomobject]@{ UserPrincipalName = $UserPrincipalName; License = $LicenseDisplayName; Action = 'NoChange' }
        return
    }

    if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Update license $LicenseDisplayName")) {
        Write-Verbose "Updating license configuration for '$UserPrincipalName'."
        Set-MgUserLicense -UserId $user.Id -AddLicenses @(@{ SkuId = $sku.SkuId; DisabledPlans = $disabledPlans }) -RemoveLicenses @($sku.SkuId) -ErrorAction Stop
        [pscustomobject]@{ UserPrincipalName = $UserPrincipalName; License = $LicenseDisplayName; Action = 'Updated'; DisabledPlans = $disabledPlans }
    }
    return
}

if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Assign license $LicenseDisplayName")) {
    Write-Verbose "Assigning license '$LicenseDisplayName' to '$UserPrincipalName'."
    $addLicense = @{ SkuId = $sku.SkuId; DisabledPlans = $disabledPlans }
    Set-MgUserLicense -UserId $user.Id -AddLicenses @($addLicense) -RemoveLicenses @() -ErrorAction Stop
    [pscustomobject]@{ UserPrincipalName = $UserPrincipalName; License = $LicenseDisplayName; Action = 'Assigned'; DisabledPlans = $disabledPlans }
}
