# Contributing

Thanks for helping build the Windows SRE automation portfolio! To keep things predictable:

1. **Open a pull request** for every change. Drafts are welcome while you iterate.
2. **Run the CI checks locally** (Pester and PSScriptAnalyzer) before pushing. Use `Invoke-Pester -Path Tests` and `Invoke-ScriptAnalyzer -Path src,Tests -Recurse`.
3. **Follow the coding standards** in `.editorconfig` and keep PowerShell scripts formatted with two-space indentation.
4. **Write or update tests** when you add automation or change behaviour.
5. **Let CI finish**; only merge once the `CI` workflow is green.

Questions or ideas? Open an issue and we can plan the next automation together.
