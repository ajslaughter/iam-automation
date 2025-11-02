# Identity Lab Automation Toolkit

This folder contains helper scripts that support the lab identity scenarios in the Windows SRE automation portfolio. The scripts simulate typical IAM flows such as creating and disabling lab users, generating access reports, and experimenting with change tooling.

---

## 📁 Directory structure

```
src/
└── Scripts/
    └── Identity/
        ├── New-LabUser.ps1              # Creates lab user accounts
        ├── Disable-LabUser.ps1          # Disables lab user accounts
        ├── Export-AccessReport.ps1      # Generates sample access reviews
        └── Modules/
            ├── bulk_provision.ps1            # Provision users from users.csv
            ├── cleanup_expired_accounts.ps1  # Stub for cleanup scenarios
            ├── common.psm1                   # Shared logging utilities
            ├── enforce_mfa_stub.ps1          # Placeholder for MFA enforcement
            ├── Invoke-IntegrationStack.ps1   # Example release automation helper
            ├── list_user_groups.ps1          # Output sample group membership
            ├── parse_login_attempts.ps1      # Parse demo login logs
            ├── reset_password.ps1            # Reset a lab user password
            └── users.csv                     # Sample data for bulk provisioning
```

---

## 🚀 Usage examples

```powershell
# Provision a single lab user
& "$PSScriptRoot/../New-LabUser.ps1" -Username "jdoe"

# Disable a lab user
& "$PSScriptRoot/../Disable-LabUser.ps1" -Username "jdoe"

# Bulk import users from CSV
& "$PSScriptRoot/bulk_provision.ps1"

# Reset a user password
& "$PSScriptRoot/reset_password.ps1" -Username "jdoe" -NewPassword "TempPass123"

# Produce a simple access report
& "$PSScriptRoot/../Export-AccessReport.ps1" -Username "jdoe"
```

---

## 📌 Notes

- `common.psm1` exposes logging helpers consumed by each script.
- The scripts operate in a simulated lab context so they are safe to run without Active Directory access.
- Extend the toolkit by wrapping your own identity automation scenarios under `src/Scripts/Identity`.
