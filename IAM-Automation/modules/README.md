# IAM-Automation Tool

A lightweight PowerShell-based tool for automating basic Identity and Access Management (IAM) operations. Includes scripts for provisioning, deprovisioning, and reviewing user access across systems.

## 📁 Directory Structure

```
IAM-AUTOMATION/
├── modules/
│   └── common.psm1           # Shared logging utilities
├── provision_user.ps1        # Creates and sets up new user accounts
├── deprovision_user.ps1      # Disables and removes user accounts
├── review_access.ps1         # Simulates access review process
└── README.md
```

## ⚙️ Requirements

- PowerShell 5.1+ (Windows) or PowerShell 7+ (cross-platform)
- No external dependencies

## 🚀 How to Use

Each script accepts a `-Username` parameter:

### Provision a User

```powershell
.\provision_user.ps1 -Username "jdoe"
```

### Deprovision a User

```powershell
.\deprovision_user.ps1 -Username "jdoe"
```

### Review User Access

```powershell
.\review_access.ps1 -Username "jdoe"
```

## 🔧 Logging

Each script logs actions to the console with timestamps using a centralized logger in `modules/common.psm1`.

Example log output:

```
[2025-05-28 14:00:00] Provisioned user: jdoe
```

## 🔒 Features

- Modular code structure
- Reusable logging logic
- Clear lifecycle simulation for IAM operations
```