# Hybrid Identity Automation

## Prerequisites

1. Install the Microsoft Graph PowerShell SDK modules required by the scripts:

```powershell
Install-Module Microsoft.Graph -Scope AllUsers
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Identity.DirectoryManagement
```

2. Create an app registration with delegated permissions for `User.ReadWrite.All` and `Directory.ReadWrite.All`, then grant admin consent.
3. Register the client secret (or certificate) with SecretManagement:

```powershell
$secureSecret = Read-Host 'Enter Graph client secret' -AsSecureString
Set-Secret -Name 'IamLab-GraphClientSecret' -Secret $secureSecret
```

4. Enable hybrid identity automation by setting `"HybridIdentity": true` in `config\features.json`.

## Creating or updating a cloud user

```powershell
Connect-MgGraph -Scopes 'User.ReadWrite.All','Directory.ReadWrite.All'
$password = Read-Host 'Temporary password' -AsSecureString
.\src\Scripts\Hybrid\New-CloudUser.ps1 -UserPrincipalName 'alex.doe@contoso.com' -DisplayName 'Alex Doe' -GivenName 'Alex' -Surname 'Doe' -Department 'IT' -JobTitle 'Systems Engineer' -Password $password -ForcePasswordChange
```

## Assigning licenses

```powershell
Connect-MgGraph -Scopes 'User.ReadWrite.All','Directory.ReadWrite.All'
.\src\Scripts\Hybrid\Set-CloudLicense.ps1 -UserPrincipalName 'alex.doe@contoso.com' -LicenseDisplayName 'ENTERPRISEPREMIUM' -EnabledPlans 'EXCHANGE_S_ENTERPRISE', 'MCOSTANDARD'
```

The scripts confirm the feature flag, ensure required modules are available, and only make changes when differences are detected. All operations support `-WhatIf` for dry runs.
