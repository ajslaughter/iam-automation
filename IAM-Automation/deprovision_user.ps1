# File: deprovision_user.ps1

param (
    [string]$Username
)

Import-Module "$PSScriptRoot\modules\common.psm1"

try {
    Log-Message "Deprovisioning user: $Username"

    # Simulate deprovisioning steps
    Log-Message " - Removing from groups..."
    Log-Message " - Revoking access..."
    Log-Message " - Disabling account..."

    Log-Message "User $Username deprovisioned successfully."
}
catch {
    Log-Message ("Error deprovisioning user {0}: {1}" -f $Username, $_)
}
