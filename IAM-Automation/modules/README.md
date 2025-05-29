# IAM-Automation Tool

A lightweight PowerShell-based tool for automating essential Identity and Access Management (IAM) operations. Includes scripts for user provisioning, deprovisioning, password resets, group auditing, access reviews, and more.

---

## 📁 Directory Structure

```
IAM-AUTOMATION/
│
├── modules/
│   ├── bulk_provision.ps1           # Provision multiple users from CSV
│   ├── cleanup_expired_accounts.ps1 # Stub: Remove expired/stale accounts
│   ├── common.psm1                  # Shared logging utilities
│   ├── enforce_mfa_stub.ps1         # Stub: Placeholder for MFA logic
│   ├── list_user_groups.ps1         # View user group membership
│   ├── parse_login_attempts.ps1     # Parse login attempts from logs
│   ├── reset_password.ps1           # Reset user password
│
├── provision_user.ps1              # Creates and sets up new user accounts
├── deprovision_user.ps1            # Disables and removes user accounts
├── review_access.ps1               # Simulates access review process
├── users.csv                       # Sample CSV for bulk provisioning
└── README.md                       # Project documentation
```

---

## ✅ Requirements

- PowerShell 5.1+ (Windows) or PowerShell 7+ (cross-platform)
- No external dependencies (simulated AD commands used)

---

## 🚀 How to Use

Each script accepts parameters from the command line. Examples:

```powershell
# Provision a single user
.\provision_user.ps1 -FirstName "Jane" -LastName "Doe" -Username "jdoe" -Department "IT" -Role "Analyst"

# Deprovision a user
.\deprovision_user.ps1 -Username "jdoe"

# Bulk import users from CSV
.\modules\bulk_provision.ps1

# Reset a user password
.\modules\reset_password.ps1 -Username "jdoe" -NewPassword "TempPass123"

# List user group memberships
.\modules\list_user_groups.ps1 -Username "jdoe"

# Simulate access review
.\review_access.ps1 -Username "jdoe"

# Stub: Enforce MFA
.\modules\enforce_mfa_stub.ps1 -Username "jdoe"

# Stub: Cleanup expired accounts
.\modules\cleanup_expired_accounts.ps1

# Parse login attempts from a sample log file
.\modules\parse_login_attempts.ps1 -LogPath ".\logs\iam_log.txt"
```

---

## 📌 Notes

- Each script uses a shared logging function defined in `common.psm1`.
- All core IAM tasks are simulated for safe testing.
- The tool can be extended to support real Active Directory or cloud-based identity systems.
