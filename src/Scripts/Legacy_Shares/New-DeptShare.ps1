[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Dept,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$RootPath = 'D:\\Shares',

    [Parameter()]
    [switch]$IncludeAuthenticatedUsersRead
)

#requires -Modules Microsoft.PowerShell.Management, SmbShare

$folderPath = Join-Path -Path $RootPath -ChildPath $Dept
$shareName = ($Dept -replace '\\s+', '') + '$'
$groupName = "GG_${Dept}_All"

Write-Verbose "Ensuring departmental folder exists at '$folderPath'."
if (-not (Test-Path -Path $folderPath)) {
    if ($PSCmdlet.ShouldProcess($folderPath, 'Create departmental folder')) {
        New-Item -Path $folderPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
        Write-Verbose "Created directory '$folderPath'."
    }
} else {
    Write-Verbose "Directory '$folderPath' already present."
}

if (-not (Test-Path -Path $folderPath)) {
    throw "Folder '$folderPath' could not be validated."
}

$acl = Get-Acl -Path $folderPath -ErrorAction Stop
$beforeAcl = $acl.Access | ForEach-Object { "{0}:{1}:{2}" -f $_.IdentityReference.Value, $_.FileSystemRights, $_.AccessControlType }

$inheritFlags = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
$propFlags = [System.Security.AccessControl.PropagationFlags]::None

$desiredRules = @()
$desiredRules += New-Object System.Security.AccessControl.FileSystemAccessRule($groupName, [System.Security.AccessControl.FileSystemRights]::Modify, $inheritFlags, $propFlags, [System.Security.AccessControl.AccessControlType]::Allow)
$desiredRules += New-Object System.Security.AccessControl.FileSystemAccessRule('Domain Admins', [System.Security.AccessControl.FileSystemRights]::FullControl, $inheritFlags, $propFlags, [System.Security.AccessControl.AccessControlType]::Allow)
if ($IncludeAuthenticatedUsersRead) {
    $desiredRules += New-Object System.Security.AccessControl.FileSystemAccessRule('Authenticated Users', [System.Security.AccessControl.FileSystemRights]::ReadAndExecute, $inheritFlags, $propFlags, [System.Security.AccessControl.AccessControlType]::Allow)
}

$changed = $false
foreach ($rule in $desiredRules) {
    $existingRule = $acl.Access | Where-Object { $_.IdentityReference -eq $rule.IdentityReference }
    if (-not $existingRule -or $existingRule.FileSystemRights -ne $rule.FileSystemRights) {
        Write-Verbose "Applying NTFS rule for '$($rule.IdentityReference)' with rights '$($rule.FileSystemRights)'."
        $acl.SetAccessRule($rule)
        $changed = $true
    }
}

if ($changed) {
    $afterAcl = $acl.Access | ForEach-Object { "{0}:{1}:{2}" -f $_.IdentityReference.Value, $_.FileSystemRights, $_.AccessControlType }
    Write-Verbose "NTFS ACL before: $($beforeAcl -join '; ')"
    Write-Verbose "NTFS ACL after:  $($afterAcl -join '; ')"
    if ($PSCmdlet.ShouldProcess($folderPath, 'Update NTFS permissions')) {
        Set-Acl -Path $folderPath -AclObject $acl -ErrorAction Stop
    }
} else {
    Write-Verbose 'NTFS permissions already compliant.'
}

try {
    $share = Get-SmbShare -Name $shareName -ErrorAction Stop
    Write-Verbose "Share '$shareName' already exists for path '$($share.Path)'."
} catch {
    if ($PSCmdlet.ShouldProcess($shareName, "Create SMB share for '$folderPath'")) {
        Write-Verbose "Creating SMB share '$shareName' for '$folderPath'."
        New-SmbShare -Name $shareName -Path $folderPath -FullAccess 'Domain Admins' -ChangeAccess $groupName -ErrorAction Stop | Out-Null
        if ($IncludeAuthenticatedUsersRead) {
            Grant-SmbShareAccess -Name $shareName -AccountName 'Authenticated Users' -AccessRight Read -Force -ErrorAction Stop | Out-Null
        }
        $share = Get-SmbShare -Name $shareName -ErrorAction Stop
    } else {
        $share = $null
    }
}

if ($share) {
    $desiredShareAces = @(
        @{ Account = 'Domain Admins'; Access = 'Full' },
        @{ Account = $groupName; Access = 'Change' }
    )
    if ($IncludeAuthenticatedUsersRead) {
        $desiredShareAces += @{ Account = 'Authenticated Users'; Access = 'Read' }
    }

    foreach ($entry in $desiredShareAces) {
        $current = Get-SmbShareAccess -Name $shareName -ErrorAction Stop | Where-Object { $_.Name -eq $entry.Account -and $_.AccessControlType -eq 'Allow' }
        if (-not $current -or $current.AccessRight -ne $entry.Access) {
            if ($PSCmdlet.ShouldProcess($shareName, "Grant SMB $($entry.Access) to $($entry.Account)")) {
                Write-Verbose "Granting SMB access '$($entry.Access)' to '$($entry.Account)'."
                Grant-SmbShareAccess -Name $shareName -AccountName $entry.Account -AccessRight $entry.Access -Force -ErrorAction Stop | Out-Null
            }
        }
    }
}
