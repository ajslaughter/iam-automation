Import-Module Pester

$identityRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\src\Scripts\Identity'

Describe 'Identity script layout' {
    It 'contains the renamed lab user scripts' {
        $expectedScripts = @(
            'New-DeptStructure.ps1',
            'New-LabUser.ps1',
            'Disable-LabUser.ps1',
            'Export-AccessReport.ps1'
        )

        foreach ($scriptName in $expectedScripts) {
            $fullPath = Join-Path -Path $identityRoot -ChildPath $scriptName
            Test-Path -LiteralPath $fullPath | Should -BeTrue
        }
    }

    It 'keeps the module helpers under Modules/' {
        $modulesPath = Join-Path -Path $identityRoot -ChildPath 'Modules'
        Test-Path -LiteralPath $modulesPath | Should -BeTrue
    }
}
