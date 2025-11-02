# Temporary CI smoke test — remove once real tests are in.

Describe 'CI smoke tests' {
    It 'detects at least one expected repository path' {
        $repoRoot = (Resolve-Path -Path (Join-Path $PSScriptRoot '..')).ProviderPath
        $expectedPaths = @('src', 'Src', 'modules', 'Modules', 'IAM-Automation', 'scripts')
        $found = $false

        foreach ($relativePath in $expectedPaths) {
            $fullPath = Join-Path -Path $repoRoot -ChildPath $relativePath
            if (Test-Path -Path $fullPath) {
                $found = $true
                break
            }
        }

        $found | Should -BeTrue -Because 'At least one expected repository path should exist so CI can run a smoke test.'
    }
}

$true
