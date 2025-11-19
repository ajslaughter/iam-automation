# IAM Automation Tool

> Last updated: 2025-11-19

![CI](https://github.com/ajslaughter/iam-automation/actions/workflows/ci.yml/badge.svg)

Hands-on, production-grade PowerShell for Windows SRE scenarios. Every automation ships with tests, continuous integration, and a pull-request workflow so changes stay reviewable and reliable.

## What's inside

- **Identity Management** – provisioning scripts, access reviews, and helper modules.
- **Group Policy Management** – opinionated baselines and import/export automation.
- **Patch Management** – Windows Update compliance reporting and remediation scaffolding.
- **Health & Disaster Recovery** – health checks, drift reports, and recovery references.
- **Hybrid Identity** – scripts for cloud-connected and cross-domain tasks.

## Quick start

```powershell
Import-Module .\src\Modules\IamLab\IamLab.psm1 -Force
.\src\Scripts\Identity\New-LabUser.ps1 -Username 'lab.engineer'
.\src\Patch\Get-WindowsUpdateCompliance.ps1 -ComputerName 'srv01' -OutputPath '.\out\patch'
```

## Completed automations

- Identity Management – Active Directory structure bootstrap [`src/Scripts/Identity/New-DeptStructure.ps1`](src/Scripts/Identity/New-DeptStructure.ps1)
- Patch Management – Windows Update compliance reporting [`src/Patch/Get-WindowsUpdateCompliance.ps1`](src/Patch/Get-WindowsUpdateCompliance.ps1)

## Patch Management — Windows Update Compliance

Generate a per-host view of pending Windows Updates without triggering installations or reboots.

### Usage

```powershell
# Example
.\src\Patch\Get-WindowsUpdateCompliance.ps1 -ComputerName 'srv01','srv02' -Verbose
```

### Output

Each run creates timestamped reports inside `out/patch` (or the path passed to `-OutputPath`):

- `<yyyyMMdd-HHmmss>-compliance.json`
- `<yyyyMMdd-HHmmss>-compliance.html` (omit when `-AsJsonOnly` is supplied)

The JSON report is an array of objects with the following fields:

| Field | Description |
| --- | --- |
| `ComputerName` | Target host name. |
| `Timestamp` | ISO-8601 timestamp of the scan. |
| `Updates` | Pending update entries with `KB`, `Title`, `Severity`, `Size`, and `Category`. |
| `LastInstall` | Timestamp of the most recent installed update (if available). |
| `RebootRequired` | `True`, `False`, or `null` when the reboot status cannot be determined. |
| `Errors` | Array of error strings captured for the host. |

The HTML report summarizes each host (update count, last install, reboot requirement, and errors) in a table for quick review.
# IAM Automation Lab

This repository provides repeatable automation for building and maintaining the IAM Lab environment. Scripts are grouped under `src/Scripts` and can be executed directly after importing the `IamLab` module (see `src/Modules/IamLab`).

## Quick start

```powershell
# Load the module and initialize the environment
Import-Module .\src\Modules\IamLab\IamLab.psm1 -Force
.\src\Scripts\Initialize-Environment.ps1 -Verbose
```

## Applying a workstation hardening baseline

```powershell
# Create or update the baseline GPO definition
.\src\Scripts\GPO\New-LabGpo.ps1 -Name 'Hardening-Workstations' -Comment 'Baseline hardening settings' -Owner 'CORP\\IAM Admins' -Verbose

# Import configuration drift from versioned backups
.\src\Scripts\GPO\Import-LabGpoBackup.ps1 -Name 'Hardening-Workstations' -Verbose

# Link the policy to the IT workstation organizational unit
.\src\Scripts\GPO\Link-LabGpo.ps1 -Name 'Hardening-Workstations' -TargetOUDN 'OU=IT Workstations,OU=Company,DC=corp,DC=local' -LinkOrder 1 -Verbose
```

Each command supports `-WhatIf` to preview the actions before they are applied and can be run repeatedly without causing duplicate changes.

## Scheduling health checks

```powershell
$actionHealth = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File %~dp0src\Scripts\Health\Test-LabHealth.ps1'
$triggerHealth = New-ScheduledTaskTrigger -Daily -At 3am
Register-ScheduledTask -TaskName 'IamLab-HealthCheck' -Action $actionHealth -Trigger $triggerHealth -Description 'Nightly domain controller health verification'

$actionDrift = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File %~dp0src\Scripts\Health\Invoke-DriftReport.ps1'
$triggerDrift = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 4am
Register-ScheduledTask -TaskName 'IamLab-DriftReport' -Action $actionDrift -Trigger $triggerDrift -Description 'Weekly configuration drift export'
```
