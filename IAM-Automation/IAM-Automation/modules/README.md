# IAM-Automation Toolkit

## 🛠 Overview

A PowerShell-based toolkit for automating Identity and Access Management (IAM) tasks in Active Directory environments. Built to support lifecycle operations like provisioning, deprovisioning, access reviews, security group assignments, OU and GPO management, and MFA enforcement logic.

Designed for real-world job readiness and repeatable deployment in domain environments.

---

## 📁 Project Structure

| File | Description |
|------|-------------|
| `setup_environment.ps1` | Full domain test environment setup: OUs, users, groups |
| `main.ps1` | CLI launcher for the toolkit |
| `common.psm1` | Shared functions, including `Write-Log` |
| `provision_user.ps1` | Creates a new AD user |
| `deprovision_user.ps1` | Disables a user and removes them from groups |
| `reset_password.ps1` | Securely resets a user password |
| `secgroup_add_user.ps1` | Adds one user to a
