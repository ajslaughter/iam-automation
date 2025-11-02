@{
    RootModule        = 'IamLab.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'd0ab2f87-2f2e-4f2e-a95a-14f50ffb0f7d'
    Author            = 'IAM Automation Team'
    CompanyName       = 'IAM Automation'
    Copyright        = "(c) 2024 IAM Automation. All rights reserved."
    Description       = 'PowerShell automation helpers for building lab Active Directory environments.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'New-LabOU',
        'New-LabSecurityGroup',
        'New-LabUser',
        'Add-LabUserToGroup',
        'Disable-LabUser',
        'Remove-LabUserFromGroup',
        'Test-LabAdAvailable'
    )
    AliasesToExport   = @()
    CmdletsToExport   = @()
    VariablesToExport = @()
    PrivateData       = @{}
}
