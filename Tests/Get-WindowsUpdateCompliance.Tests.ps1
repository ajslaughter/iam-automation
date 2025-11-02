Import-Module Pester

$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath '..\src\Patch\Get-WindowsUpdateCompliance.ps1'

Describe 'Get-WindowsUpdateCompliance.ps1' {
    BeforeAll {
        $global:MockDate = [datetime]'2024-01-02T09:30:00Z'
    }

    BeforeEach {
        Mock Get-Date { return $global:MockDate }
        Mock Get-Module { @([pscustomobject]@{ Name = 'PSWindowsUpdate' }) } -ParameterFilter { $Name -eq 'PSWindowsUpdate' -and $ListAvailable }
        Mock Get-Module { @() } -ParameterFilter { $Name -eq 'PSWindowsUpdate' -and -not $ListAvailable }
        Mock Save-Module {}
        Mock Import-Module {}

        Mock Get-WUHistory { @([pscustomobject]@{ Date = [datetime]'2023-12-31T12:00:00Z' }) }
        Mock Get-WURebootStatus { [pscustomobject]@{ RebootRequired = $false } }
    }

    Context 'Output generation' {
        It 'creates the output directory and writes JSON and HTML files' {
            Mock Get-WUList {
                @([pscustomobject]@{ KB = 'KB123456'; Title = 'Security Update'; MsrcSeverity = 'Critical'; Size = 1024; Categories = 'Security Updates' })
            }

            $outputPath = Join-Path -Path $TestDrive -ChildPath 'reports'

            $result = & $scriptPath -ComputerName 'server01' -OutputPath $outputPath

            $result | Should -HaveCount 1
            $result[0].ComputerName | Should -Be 'server01'
            (Test-Path -LiteralPath $outputPath) | Should -BeTrue

            $expectedPrefix = Join-Path -Path $outputPath -ChildPath '20240102-093000-compliance'
            (Test-Path -LiteralPath ($expectedPrefix + '.json')) | Should -BeTrue
            (Test-Path -LiteralPath ($expectedPrefix + '.html')) | Should -BeTrue

            $jsonContent = Get-Content -LiteralPath ($expectedPrefix + '.json') -Raw | ConvertFrom-Json
            $jsonContent[0].Updates[0].KB | Should -Be 'KB123456'
        }

        It 'skips HTML output when -AsJsonOnly is specified' {
            Mock Get-WUList { @() }
            $outputPath = Join-Path -Path $TestDrive -ChildPath 'jsonOnly'

            & $scriptPath -ComputerName 'server01' -OutputPath $outputPath -AsJsonOnly

            $expectedPrefix = Join-Path -Path $outputPath -ChildPath '20240102-093000-compliance'
            (Test-Path -LiteralPath ($expectedPrefix + '.json')) | Should -BeTrue
            (Test-Path -LiteralPath ($expectedPrefix + '.html')) | Should -BeFalse
        }
    }

    Context 'Parameter handling' {
        It 'includes drivers when -IncludeDrivers is specified' {
            Mock Get-WUList { @() }

            & $scriptPath -ComputerName 'server01' -IncludeDrivers | Out-Null

            Assert-MockCalled Get-WUList -ParameterFilter { $UpdateType -eq 'SoftwareAndDriver' } -Times 1
        }
    }

    Context 'Error handling' {
        It 'continues processing when a computer fails and records the error' {
            Mock Get-WUList {
                if ($ComputerName -eq 'bad-host') {
                    throw [System.Exception]::new('RPC server unavailable')
                }
                else {
                    @()
                }
            }

            $outputPath = Join-Path -Path $TestDrive -ChildPath 'partial'
            $result = & $scriptPath -ComputerName 'good-host','bad-host' -OutputPath $outputPath

            $result | Should -HaveCount 2
            ($result | Where-Object ComputerName -eq 'bad-host').Errors | Should -Not -BeNullOrEmpty
            ($result | Where-Object ComputerName -eq 'good-host').Errors | Should -BeNullOrEmpty
        }

        It 'throws when OutputPath points to an existing file' {
            Mock Get-WUList { @() }
            $tempFile = Join-Path -Path $TestDrive -ChildPath 'file.txt'
            Set-Content -LiteralPath $tempFile -Value 'placeholder'

            { & $scriptPath -OutputPath $tempFile } | Should -Throw
        }
    }
}
