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
