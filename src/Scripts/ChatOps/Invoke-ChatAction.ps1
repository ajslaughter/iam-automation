[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)]
    [string]$WebhookUri,

    [Parameter(Mandatory)]
    [string]$Summary,

    [Parameter()]
    [ValidateSet('Slack', 'Teams')]
    [string]$Platform = 'Slack',

    [Parameter()]
    [string]$ApprovalId,

    [Parameter()]
    [string]$ApprovalToken,

    [Parameter()]
    [string]$Result
)

if (-not (Get-IamLabFeatureFlag -Name 'ChatOps' -AsBoolean)) {
    Write-Warning 'ChatOps automation is disabled. Enable it in config/features.json before running chat workflows.'
    return
}

$secret = Get-IamLabSecret -Name 'IamLab-ChatOpsSecret' -AllowFallback
if ($secret -is [System.Management.Automation.PSCredential]) {
    $sharedSecret = $secret.GetNetworkCredential().Password
} else {
    $sharedSecret = [string]$secret
}

if (-not $sharedSecret) {
    throw 'ChatOps shared secret is not configured. Set IamLab-ChatOpsSecret via SecretManagement.'
}

function Get-HmacToken {
    param([string]$Input)
    $hmac = [System.Security.Cryptography.HMACSHA256]::new([System.Text.Encoding]::UTF8.GetBytes($sharedSecret))
    $hash = $hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Input))
    [Convert]::ToBase64String($hash)
}

if ($ApprovalToken) {
    if (-not $ApprovalId) {
        throw 'ApprovalId must be supplied when validating an approval token.'
    }
    $expected = Get-HmacToken -Input $ApprovalId
    if ($expected -ne $ApprovalToken) {
        throw 'Approval token validation failed. Ensure the approver used the correct shared secret.'
    }
    Write-Verbose "Approval token validated for '$ApprovalId'."
    if ($Result -and $PSCmdlet.ShouldProcess($WebhookUri, 'Post approval result')) {
        $payload = switch ($Platform) {
            'Teams' { @{ text = "Approved: $Result" } }
            default { @{ text = "Approved: $Result" } }
        }
        Invoke-RestMethod -Method Post -Uri $WebhookUri -Body (ConvertTo-Json $payload -Depth 4) -ContentType 'application/json'
    }
    return [pscustomobject]@{ Approved = $true; ApprovalId = $ApprovalId; ResultPosted = [bool]$Result }
}

$payloadText = $Summary
if ($ApprovalId) {
    $tokenHint = Get-HmacToken -Input $ApprovalId
    $payloadText += "`nApproval ID: $ApprovalId`nSubmit token via Invoke-ChatAction -ApprovalId $ApprovalId -ApprovalToken <Base64>."
    Write-Verbose "Generated approval hint token (for validation only)."
}

$payload = switch ($Platform) {
    'Teams' { @{ text = $payloadText } }
    default { @{ text = $payloadText } }
}

if ($PSCmdlet.ShouldProcess($WebhookUri, 'Post chat notification')) {
    Invoke-RestMethod -Method Post -Uri $WebhookUri -Body (ConvertTo-Json $payload -Depth 4) -ContentType 'application/json'
}

[pscustomobject]@{
    Sent        = $true
    Platform    = $Platform
    ApprovalId  = $ApprovalId
}
