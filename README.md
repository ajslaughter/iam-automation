# AP Field Operations Automation Toolkit

**A specialized automation suite designed for Systems Analysts supporting regional construction job sites.**

This toolkit focuses on Incident and Injury Free (IIF) safety compliance, rapid site connectivity diagnostics, and standardized endpoint mobilization. It is designed to provide "Day 1" value for Field Operations.

## Features

- **Safety First**: Enforces safety culture with mandatory safety briefs and hazard checks.
- **Site Connectivity**: Rapidly diagnoses network issues (Latency, VPN, Meraki) at remote sites.
- **Workstation Prep**: Automates the setup of field and office laptops, ensuring consistency and speed.
- **Legacy Support**: Includes legacy identity management scripts for backward compatibility.

## Usage

### 1. Safety Brief
Enforce safety protocols before starting work.
```powershell
.\src\Scripts\Safety\Invoke-SafetyBrief.ps1
```

### 2. Site Connectivity Test
Diagnose network issues at a remote job site.
```powershell
.\src\Scripts\Network\Test-SiteConnectivity.ps1
```

### 3. Workstation Preparation
Prepare a new laptop for a Field Engineer or Office Staff.
```powershell
# For Field Staff (Installs Bluebeam, Citrix)
.\src\Scripts\Client\Invoke-WorkstationPrep.ps1 -RoleProfile Field

# For Office Staff (Installs Office 365, Teams)
.\src\Scripts\Client\Invoke-WorkstationPrep.ps1 -RoleProfile Office
```

## Project Structure

```text
src/
├── Scripts/
│   ├── Safety/          # Safety protocols and checks
│   ├── Network/         # Connectivity diagnostics
│   ├── Client/          # Endpoint preparation
│   └── Legacy_Backend/  # Legacy identity management scripts
├── Modules/             # Shared PowerShell modules
└── ...
```

## Configuration

Configuration is managed in `config/features.json`. Ensure `"SafetyChecks": true` is enabled.

## Documentation

- [Safety Protocols](docs/SAFETY_PROTOCOLS.md)
