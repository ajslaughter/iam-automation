# IAM Lab Runbook

This runbook guides day-one and week-one operations for the IAM Lab Automation Toolkit. All commands support `-WhatIf` and `-Confirm`; begin with `-WhatIf` to verify the plan before committing changes.

## Day-One Checklist

1. **Validate prerequisites**
   - Ensure RSAT (ActiveDirectory) is installed on the management host.
   - Confirm network connectivity to a domain controller.

2. **Import the module**
   ```powershell
   Import-Module .\src\Modules\IamLab\IamLab.psd1 -Force
   ```

3. **Run environment initialization**
   ```powershell
   .\src\Scripts\Initialize-Environment.ps1 -Verbose -WhatIf
   ```
   Review the WhatIf output, then rerun without the switch to create/update:
   ```powershell
   .\src\Scripts\Initialize-Environment.ps1 -Verbose
   ```

4. **Build the sample organization**
   ```powershell
   .\src\Scripts\Build-Org.ps1 -Verbose -WhatIf
   ```
   If satisfied, rerun without `-WhatIf` to provision the baseline lab users and group memberships.

## Week-One Operations

### Bulk Provisioning from CSV
1. Update `config/users.users.csv.sample` (or copy to a new file) with the target user list. Required headers:
   `SamAccountName,GivenName,Surname,OU,Email,Title,Department,AddToGroups`
2. Execute the bulk provisioner:
   ```powershell
   .\src\Scripts\Invoke-BulkProvision.ps1 -Path .\config\users.users.csv.sample -Verbose -WhatIf
   ```
3. Review the summary table and log output, then rerun without `-WhatIf` to commit changes.

### Bulk Deprovisioning
- Disable specific accounts:
  ```powershell
  .\src\Scripts\Invoke-BulkDeprovision.ps1 -SamAccountName jsmith,adoe -Verbose -WhatIf
  ```
- Deprovision from a CSV list containing `SamAccountName` values:
  ```powershell
  .\src\Scripts\Invoke-BulkDeprovision.ps1 -InputCsv .\offboarding.csv -Verbose
  ```
  A dated CSV report is generated in the logs directory (`logs/<yyyy-MM-dd>/deprovision.csv`).

### Access Reviews
Generate a point-in-time view of all `GG_*` security groups and members:
```powershell
.\src\Scripts\Export-GroupsAndMembers.ps1 -Verbose
```
The resulting CSV is stored under `logs/<yyyy-MM-dd>/groups.csv`.

## Troubleshooting

| Symptom | Suggested Action |
| --- | --- |
| `ActiveDirectory` module not found | Install RSAT (Windows Features > RSAT: Active Directory Domain Services and Lightweight Directory Tools) and reopen PowerShell. |
| `Get-ADDomain` failures | Verify domain controller connectivity and DNS resolution. Use `Test-LabAdAvailable` to confirm availability. |
| Access denied errors | Ensure your account has rights to create/manage objects in the target OU structure. |
| DNS or replication delays | Allow time for AD replication or run commands against a specific domain controller using the `-Server` parameter on AD cmdlets if needed. |
| Logging directory cannot be created | Verify write permissions to the configured `LoggingRoot` path or provide `-LogPath` to an alternate location. |

## Secrets and Passwords

The lab module uses `Get-DefaultPassword` to supply a placeholder password. For production labs:
1. Install the PowerShell SecretManagement and SecretStore modules.
2. Register a vault and store the default password with the name defined by `DefaultPasswordSecretName` in the configuration file.
3. Update the helpers to call `Get-Secret` (documented in README) before onboarding real users.

## Support

Open issues or improvement requests via the repository issue tracker. Include log snippets from `logs/<yyyy-MM-dd>/IamLab.log` for faster triage.
