# IAM Lab Automation Toolkit

The IAM Lab Automation Toolkit provides a set of production-ready PowerShell commands and runbooks for building and maintaining a lab-scale Active Directory environment. The tooling targets Windows Server 2019/2022 domain controllers or workstations with the RSAT feature installed.

## Prerequisites

- Windows Server domain controller or Windows 10/11 host with RSAT (Active Directory module).
- PowerShell 5.1 or later (tested with PowerShell 7 in CI).
- Permissions to create and manage objects in the target Active Directory domain.
- Clone or download this repository to a working directory on the management host.

## Quickstart

1. **Clone the repository**
   ```powershell
   git clone <repo-url>
   cd IAM-Automation
   ```

2. **Configure the environment**
   Update the JSON file at `config/IamLab.config.json` to reflect your directory structure. The default shape is:
   ```json
   {
     "DomainDN": "DC=corp,DC=local",
     "CompanyOUDN": "OU=Company,DC=corp,DC=local",
     "Departments": ["IT", "Marketing", "Finance", "Managers"],
     "DefaultPasswordSecretName": "IamLabDefaultPassword",
     "LoggingRoot": ".\\logs"
   }
   ```

3. **Import the module**
   ```powershell
   Import-Module .\src\Modules\IamLab\IamLab.psd1 -Force
   ```

4. **Run day-one tasks (start with -WhatIf)**
   ```powershell
   .\src\Scripts\Initialize-Environment.ps1 -WhatIf -Verbose
   .\src\Scripts\Build-Org.ps1 -WhatIf -Verbose
   .\src\Scripts\Invoke-BulkProvision.ps1 -WhatIf -Verbose -Path .\config\users.users.csv.sample
   ```

5. **Run for real once validated**
   Remove the `-WhatIf` switch when you are ready to apply changes.

## Configuration Reference

| Key | Description |
| --- | --- |
| `DomainDN` | Distinguished name for the Active Directory domain. |
| `CompanyOUDN` | Distinguished name of the root organizational unit that houses lab resources. |
| `Departments` | Array of departments used to seed child OUs and security groups. |
| `DefaultPasswordSecretName` | Friendly name for the default password secret (used in documentation). |
| `LoggingRoot` | Root folder where log and report subdirectories are created (defaults to `./logs`). |

## Logging

All module functions write structured messages to `./logs/<yyyy-MM-dd>/IamLab.log` by default. Override the destination with the `-LogPath` parameter on any public cmdlet or script. Bulk operations also create CSV reports in the same dated folders (for example `deprovision.csv` or `groups.csv`).

## Security Notes

The lab helper `Get-DefaultPassword` produces a well-known placeholder (`P@ssw0rd!`) for demonstration purposes. In production, integrate PowerShell SecretManagement and use `Get-Secret -Name <DefaultPasswordSecretName>` (as defined in the configuration file) to supply passwords securely. Never commit real credentials to source control.

## Example Workflow

1. Initialize the OU and security group structure.
2. Build the sample organization.
3. Import additional users from CSV (`Invoke-BulkProvision.ps1`).
4. Use `Invoke-BulkDeprovision.ps1` to disable and clean up accounts.
5. Export ongoing access reviews with `Export-GroupsAndMembers.ps1`.

All scripts honor `-WhatIf` and `-Confirm` and emit verbose details when `-Verbose` is specified.
