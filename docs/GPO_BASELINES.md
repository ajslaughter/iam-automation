# GPO Baselines

The lab ships with reusable scripts to create, import, and link hardened Group Policy Objects. Use the helpers under `src/Scripts/GPO` to stay idempotent and to take advantage of built-in verbose logging and `-WhatIf` previews.

## Creating or updating a baseline

```powershell
# Create the policy if missing and ensure metadata is aligned
.\src\Scripts\GPO\New-LabGpo.ps1 -Name 'Hardening-Workstations' -Comment 'Security baseline for corp workstations' -Owner 'CORP\\IAM Admins' -Verbose
```

## Importing from backup

```powershell
# Imports the most recent backup stored under .\config\GPO_Backups\Hardening-Workstations
.\src\Scripts\GPO\Import-LabGpoBackup.ps1 -Name 'Hardening-Workstations' -Verbose -WhatIf
```

The import helper validates that the on-disk backup metadata matches the in-domain GPO identifier before importing to prevent accidental overwrites.

## Linking to organizational units

```powershell
# Link to the IT Workstations OU with enforced order 1
.\src\Scripts\GPO\Link-LabGpo.ps1 -Name 'Hardening-Workstations' -TargetOUDN 'OU=IT Workstations,OU=Company,DC=corp,DC=local' -LinkOrder 1 -Enforced -Verbose
```

Re-running the link script is safe; it only adjusts the specific properties that differ from the requested state.
