# Departmental Share Provisioning

Use `New-DeptShare.ps1` to create a departmental file share with consistent NTFS and SMB permissions. The script is idempotent and supports `-WhatIf` for safe previews.

## Example

```powershell
# Preview creation of the Marketing share and NTFS ACLs under D:\Shares
.\src\Scripts\Shares\New-DeptShare.ps1 -Dept 'Marketing' -RootPath 'D:\Shares' -WhatIf -Verbose

# Apply the change including an Authenticated Users read grant
.\src\Scripts\Shares\New-DeptShare.ps1 -Dept 'Marketing' -RootPath 'D:\Shares' -IncludeAuthenticatedUsersRead -Verbose
```

## Rollback snippet

To remove the share while retaining an audit trail, record the current permissions and then delete the SMB share and directory:

```powershell
$shareName = 'Marketing$'
Get-SmbShareAccess -Name $shareName | Export-Csv .\backups\Marketing_share_permissions.csv -NoTypeInformation
Revoke-SmbShareAccess -Name $shareName -AccountName 'Everyone' -Force -Confirm:$false
Remove-SmbShare -Name $shareName -Force -Confirm:$false
Remove-Item -Path 'D:\Shares\Marketing' -Recurse -Force
```
