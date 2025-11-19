$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = Join-Path -Path $here -ChildPath '../src/Scripts/Identity/New-LabUser.ps1'

if (-not (Get-Command New-ADUser -ErrorAction SilentlyContinue)) {
    function global:New-ADUser { }
}
if (-not (Get-Command Write-IamLog -ErrorAction SilentlyContinue)) {
    function global:Write-IamLog { }
}

Describe 'New-LabUser' {
    Context 'When creating a new user' {
        $WhatIfPreference = $false
        
        Mock 'New-ADUser' { }
        Mock 'Write-IamLog' { }
        Mock 'Import-Module' { }

        It 'Should call New-ADUser with correct parameters' {
            { & $sut -Username 'test.user' -Enabled -WhatIf:$false } | Should Not Throw
            Assert-MockCalled 'New-ADUser' -Times 1 -ParameterFilter {
                $Name -eq 'test.user' -and $Enabled -eq $true
            }
        }
    }
}
