# AP Field Operations Automation Toolkit

> **Focus:** Day-one ready PowerShell for Systems Analysts supporting construction job sites.
> **Alignment:** IIF Safety Culture, Site Connectivity, and Endpoint Management (Meraki, SCCM).

![CI](https://github.com/ajslaughter/ap-fieldops-automation/actions/workflows/ci.yml/badge.svg)

This toolkit is a specialized automation suite designed for systems teams operating across regional job sites. It provides idempotent scripts for rapid diagnosis, secure mobilization, and compliance with the Incident and Injury Free (IIF) safety culture.

## Core Automations

| Script | Location | Job Responsibility Covered |
| :--- | :--- | :--- |
| **Invoke-SafetyBrief.ps1** | `src/Scripts/Safety` | Championing the **IIF Safety Culture**. |
| **Test-SiteConnectivity.ps1** | `src/Scripts/Network` | **Troubleshooting** network connectivity, **TCP/IP** validation. |
| **Invoke-WorkstationPrep.ps1** | `src/Scripts/Client` | **Installing/repairing hardware and software**, imaging, **SCCM** knowledge. |
| **Join-DomainAndPlace.ps1** | `src/Scripts/Computers` | Coordinating the setup and deployment of computer hardware. |

## Quick Start (Demonstrating Day 1 Value)

```powershell
# 1. Enforce IIF safety protocols before beginning work.
.\src\Scripts\Safety\Invoke-SafetyBrief.ps1 -JobSiteID 'BismarckDC-001' -Verbose

# 2. Immediately diagnose the site's network health (VPN, Meraki, Internet).
.\src\Scripts\Network\Test-SiteConnectivity.ps1 -CorpVPNEndpoint 'corp-vpn.apinc.com' -Verbose

# 3. Standardize and prep a new field laptop for a Project Manager.
.\src\Scripts\Client\Invoke-WorkstationPrep.ps1 -RoleProfile 'Field' -WhatIf
```

## Legacy Infrastructure Management
The toolkit retains full-stack capabilities for core infrastructure tasks:

- **Active Directory**: Full user provisioning, group, and OU management (Legacy_Identity).
- **Group Policy**: Idempotent GPO creation and linking for hardening baselines (Legacy_GPO).
- **Health & DR**: Domain controller health checks and configuration drift reporting (Legacy_Health, Legacy_Backup).
