# Security Guidance

## Secret retrieval

The IamLab module defers to [Microsoft.PowerShell.SecretManagement](https://learn.microsoft.com/powershell/module/microsoft.powershell.secretmanagement) for privileged credential retrieval. Register a vault and seed required secrets (for example `IamLab-DefaultAdmin`) before running automation:

```powershell
Install-Module Microsoft.PowerShell.SecretManagement -Scope AllUsers
Register-SecretVault -Name IamLab -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
Set-Secret -Name 'IamLab-DefaultAdmin' -Secret (Get-Credential -Message 'Enter the default domain admin credential')
```

When a vault is unavailable you may opt-in to the lab fallback by creating `config\secrets.json` with entries that include `UserName` and `Password`. Use the `-AllowFallback` switch on `Get-IamLabSecret` and related helpers to consume those values; omit the switch in production to enforce vault usage.

## Just Enough Administration (JEA)

Deploy the `src\Security\IamLabJEA.pssc` endpoint to expose only the exported IamLab functions:

```powershell
Register-PSSessionConfiguration -Name IamLab -Path .\src\Security\IamLabJEA.pssc -Force
Restart-Service WinRM
```

## Code signing workflow

1. Request or issue a code-signing certificate and export the thumbprint (for example `CN=IamLab Code Signing`).
2. Update `src\Modules\IamLab\IamLab.psd1` if a different subject or timestamp service is required.
3. Sign all scripts and modules prior to release:

```powershell
$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Where-Object Subject -eq 'CN=IamLab Code Signing'
Get-ChildItem -Path src -Filter *.ps1 -Recurse | Set-AuthenticodeSignature -Certificate $cert -TimestampServer 'http://timestamp.digicert.com'
Get-ChildItem -Path src\Modules -Filter *.psm1 -Recurse | Set-AuthenticodeSignature -Certificate $cert -TimestampServer 'http://timestamp.digicert.com'
```

4. Validate signatures using `Get-AuthenticodeSignature` before packaging or deployment.
