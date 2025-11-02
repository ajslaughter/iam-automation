# File: New-LabUser.ps1

param (
    [string]$Username
)

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Modules/common.psm1')

try {
    # Fake user creation
    Log-Message "Provisioning user: $Username"

    # Simulate success
    Log-Message "User $Username created successfully."
}
catch {
    Log-Message ("Error creating user {0}: {1}" -f $Username, $_)
}
