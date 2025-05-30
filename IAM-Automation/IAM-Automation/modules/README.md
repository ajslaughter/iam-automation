# IAM-Automation

This PowerShell-based IAM Automation Suite simplifies Identity and Access Management (IAM) tasks in Active Directory environments. It includes modular scripts for provisioning, deprovisioning, auditing, security group management, OU/GPO operations, and access reviews.

## 📦 Modules Overview

| Script                             | Description |
|------------------------------------|-------------|
| `bulk_provision.ps1`               | Provision multiple users from `users.csv`. |
| `bulk_user_termination.ps1`        | Disable and remove multiple users from AD. |
| `check_admin_group_changes.ps1`    | Detect changes in domain admin group membership. |
| `cleanup_domain.ps1`               | Remove all OUs and GPOs (use with caution). |
| `cleanup_expired_accounts.ps1`     | Disable/remove accounts past expiration date. |
| `common.psm1`                      | Shared utility functions for the module. |
| `create_and_link_gpo.ps1`          | Create a GPO and link it to a specific OU. |
| `create_gpo.ps1`                   | Standalone GPO creation script. |
| `create_ou.ps1`                    | Create new Organizational Units. |
| `create_security_group.ps1`        | Create a new security group. |
| `disable_stale_accounts.ps1`       | Disable AD accounts inactive for X days. |
| `enforce_mfa_stub.ps1`             | Simulated MFA enforcement logic. |
| `export_group_membership.ps1`      | Export AD group memberships to CSV. |
| `generate_access_review_report.ps1`| Generate a CSV report of group memberships for access review. |
| `link_gpo_to_ou.ps1`               | Link an existing GPO to a target OU. |
| `list_user_groups.ps1`             | List all groups a user is a member of. |
| `main.ps1`                         | Central orchestrator script (optional entry point). |
| `parse_login_attempts.ps1`         | Parse failed login attempts from event logs. |
| `request_mfa_stub.ps1`             | Simulate an MFA request (stub implementation). |
| `reset_password.ps1`               | Reset AD user passwords to a default or random secure value. |
| `secgroup_add_ou_users.ps1`        | Add all users from a given OU to a security group. |
| `secgroup_add_user.ps1`            | Add a specific user to a security group. |
| `secgroup_remove_user.ps1`         | Remove a user from a security group. |
| `setup_environment.ps1`            | Prepare AD environment for automation scripts. |

## 🛠 Standalone Scripts

| Script                | Description |
|------------------------|-------------|
| `provision_user.ps1`   | Create a single user with custom attributes. |
| `deprovision_user.ps1` | Disable and optionally remove a single user. |
| `review_access.ps1`    | Perform an individual user/group access review. |

## 📄 CSV Input Format

The `users.csv` file should follow this format for provisioning:

```csv
FirstName,LastName,Username,OU,Group,Password
John,Doe,jdoe,OU=Employees,Group=IT,Welcome123!
