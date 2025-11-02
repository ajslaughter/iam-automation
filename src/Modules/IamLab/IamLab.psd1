@{
    RootModule            = 'IamLab.psm1'
    ModuleVersion         = '1.0.0'
    GUID                  = '7c6ecf5f-036f-4c7c-9c0f-bc895cbac0aa'
    Author                = 'IAM Automation Team'
    CompanyName           = 'IAM Lab'
    Copyright             = '(c) IAM Lab. All rights reserved.'
    Description           = 'Core helpers for the IAM Lab automation platform.'
    PowerShellVersion     = '5.1'
    CompatiblePSEditions  = @('Desktop', 'Core')
    RequiredModules       = @('Microsoft.PowerShell.SecretManagement')
    FunctionsToExport     = @('Get-IamLabSecret', 'Get-IamLabCredential', 'Invoke-IamLabSelfTest', 'Get-IamLabFeatureFlag')
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @()
    PrivateData           = @{
        PSData = @{
            Tags        = @('IAM', 'Automation', 'Lab')
            ProjectUri  = 'https://github.com/example/iam-automation'
            LicenseUri  = 'https://github.com/example/iam-automation/blob/main/LICENSE'
            ReleaseNotes = 'Initial module manifest.'
        }
        Signing = @{
            CertificateSubject = 'CN=IamLab Code Signing'
            TimestampServer    = 'http://timestamp.digicert.com'
        }
    }
}
