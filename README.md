# IAM Automation

## Day 02 — Windows Update Compliance

Generate a per-host view of pending Windows Updates without triggering installations or reboots.

### Usage

```powershell
# Example
.\src\Patch\Get-WindowsUpdateCompliance.ps1 -ComputerName 'srv01','srv02' -Verbose
```

### Output

Each run creates timestamped reports inside `out/patch` (or the path passed to `-OutputPath`):

- `<yyyyMMdd-HHmmss>-compliance.json`
- `<yyyyMMdd-HHmmss>-compliance.html` (omit when `-AsJsonOnly` is supplied)

The JSON report is an array of objects with the following fields:

| Field | Description |
| --- | --- |
| `ComputerName` | Target host name. |
| `Timestamp` | ISO-8601 timestamp of the scan. |
| `Updates` | Pending update entries with `KB`, `Title`, `Severity`, `Size`, and `Category`. |
| `LastInstall` | Timestamp of the most recent installed update (if available). |
| `RebootRequired` | `True`, `False`, or `null` when the reboot status cannot be determined. |
| `Errors` | Array of error strings captured for the host. |

The HTML report summarizes each host (update count, last install, reboot requirement, and errors) in a table for quick review.
