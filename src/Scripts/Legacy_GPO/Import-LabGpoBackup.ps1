[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)]
    [string]$Name
)

#requires -Modules GroupPolicy

$repoRoot = Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..')
$backupRoot = Join-Path -Path $repoRoot -ChildPath 'config/GPO_Backups'
$gpoBackupPath = Join-Path -Path $backupRoot -ChildPath $Name

if (-not (Test-Path -Path $gpoBackupPath -PathType Container)) {
    throw "The backup path '$gpoBackupPath' was not found."
}

$backups = Get-GPOBackup -Path $gpoBackupPath -ErrorAction Stop | Where-Object { $_.DisplayName -eq $Name }
if (-not $backups) {
    throw "No backup set named '$Name' was discovered beneath '$gpoBackupPath'."
}

if ($backups.Count -gt 1) {
    Write-Verbose "Multiple backups located for '$Name'; selecting the most recent by timestamp."
    $backup = $backups | Sort-Object -Property CreationTime -Descending | Select-Object -First 1
} else {
    $backup = $backups[0]
}

try {
    $existing = Get-GPO -Name $Name -ErrorAction SilentlyContinue
} catch {
    throw "Failed to evaluate existing GPO '$Name'. $_"
}

if ($existing -and $existing.Id -ne $backup.Id) {
    throw "Existing GPO '$Name' (Id: $($existing.Id)) does not match backup Id $($backup.Id). Aborting import to prevent mismatch."
}

if ($PSCmdlet.ShouldProcess($Name, 'Import Group Policy Object from backup')) {
    Write-Verbose "Importing backup '$($backup.Id)' for '$Name' from '$gpoBackupPath'."
    Import-GPO -BackupId $backup.Id -TargetName $Name -Path $gpoBackupPath -CreateIfNeeded -ErrorAction Stop | Out-Null
    Write-Verbose "Import completed for '$Name'."
}
