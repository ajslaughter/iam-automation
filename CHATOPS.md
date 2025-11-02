# ChatOps Integration

## Setup

1. Enable the feature flag by setting `"ChatOps": true` in `config\features.json`.
2. Register or obtain an incoming webhook for your collaboration platform (Slack or Microsoft Teams).
3. Store the shared secret used for HMAC validation:

```powershell
$secret = Read-Host 'ChatOps shared secret' -AsSecureString
Set-Secret -Name 'IamLab-ChatOpsSecret' -Secret $secret
```

## Requesting approval

```powershell
.\src\Scripts\ChatOps\Invoke-ChatAction.ps1 -WebhookUri 'https://hooks.slack.com/services/...' -Summary 'Bulk deprovision pending for 12 accounts.' -Platform Slack -ApprovalId 'bulk-deprovision-20240201' -WhatIf
```

When ready to send, remove `-WhatIf`. The message contains the approval ID; an approver generates the token locally:

```powershell
$secret = Get-IamLabSecret -Name 'IamLab-ChatOpsSecret' -AllowFallback
$token = .\src\Scripts\ChatOps\Invoke-ChatAction.ps1 -WebhookUri 'https://hooks.slack.com/services/...' -Summary 'Compute token only' -Platform Slack -ApprovalId 'bulk-deprovision-20240201' -ApprovalToken (Get-Hmac) # conceptual helper
```

> Approvers can also run a small helper such as:
>
> ```powershell
> $secret = Get-IamLabSecret -Name 'IamLab-ChatOpsSecret' -AllowFallback
> $hmac = [System.Security.Cryptography.HMACSHA256]::new([System.Text.Encoding]::UTF8.GetBytes($secret))
> $token = [Convert]::ToBase64String($hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes('bulk-deprovision-20240201')))
> ```

## Posting results after approval

```powershell
.\src\Scripts\ChatOps\Invoke-ChatAction.ps1 -WebhookUri 'https://hooks.slack.com/services/...' -Summary 'Bulk deprovision pending for 12 accounts.' -Platform Slack -ApprovalId 'bulk-deprovision-20240201' -ApprovalToken $token -Result 'Accounts disabled and archived.'
```

The script validates the HMAC token using the stored shared secret, posts the result, and returns structured output so automated workflows can confirm approval status.
