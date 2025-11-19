<#!
.SYNOPSIS
    Automates creation of an integration branch and consolidation pull request.

.DESCRIPTION
    Invoke-IntegrationStack orchestrates the workflow required to collect a stack
    of pull requests on a temporary integration branch. The function creates (or
    refreshes) the integration branch from the specified base branch, retargets
    a set of open pull requests, merges them in a deterministic order, waits for
    CI to finish, and then opens a follow-up pull request back to the base
    branch with a status checklist.

    The implementation relies on the GitHub CLI (`gh`) being authenticated for
    the provided repository. All git operations are executed in the current
    working tree, allowing the script to be integrated with local automation
    pipelines.

.PARAMETER Repository
    GitHub repository in the form "owner/name". Defaults to the current
    project ("ajslaughter/iam-automation").

.PARAMETER BaseBranch
    The stable branch the integration branch should track. Defaults to
    "main".

.PARAMETER IntegrationBranch
    Name of the integration branch to create or update.

.PARAMETER PullRequestsToRetarget
    All pull requests that should have their base switched to the integration
    branch. Defaults to PRs 1 through 4.

.PARAMETER PullRequestsMergeOrder
    Ordered list of pull requests to merge into the integration branch after
    retargeting. Defaults to merging PRs 3, 2, and 1 in that order.

.PARAMETER SummaryLabel
    Identifier used in the final pull request title (for example, the stack
    date). Defaults to "2025-11-02".

.PARAMETER CiPollIntervalSeconds
    Number of seconds to wait between CI status polls. Defaults to 30 seconds.

.PARAMETER CiTimeoutMinutes
    Maximum number of minutes to wait for a CI run to complete. Defaults to
    30 minutes.

.PARAMETER DryRun
    When present, the function only prints the commands that would be executed
    without modifying git history or interacting with GitHub.

.EXAMPLE
    Invoke-IntegrationStack -IntegrationBranch "integration/stack-2025-11-02"

    Creates the integration branch, retargets PRs 1-4, merges PRs 3, 2, 1,
    waits for CI, and opens the summary pull request.

.NOTES
    The automation assumes that the GitHub CLI is installed and authenticated,
    and that the local git repository already has a remote named "origin"
    pointing to the provided repository.
#>
[CmdletBinding()]
param()

function Invoke-IntegrationStack {
    [CmdletBinding()]
    param(
        [Parameter()][string]$Repository = "ajslaughter/iam-automation",
        [Parameter()][string]$BaseBranch = "main",
        [Parameter(Mandatory = $true)][string]$IntegrationBranch,
        [Parameter()][int[]]$PullRequestsToRetarget = @(1, 2, 3, 4),
        [Parameter()][int[]]$PullRequestsMergeOrder = @(3, 2, 1),
        [Parameter()][string]$SummaryLabel = '2025-11-02',
        [Parameter()][int]$CiPollIntervalSeconds = 30,
        [Parameter()][int]$CiTimeoutMinutes = 30,
        [switch]$DryRun
    )

    $ErrorActionPreference = 'Stop'

    function Write-IntegrationLog {
        param([string]$Message)
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] $Message"
    }

    function Invoke-ExternalCommand {
        param(
            [Parameter(Mandatory = $true)][string]$Command,
            [Parameter()][string[]]$Arguments = @(),
            [switch]$Quiet
        )

        $rendered = $Command
        if ($Arguments.Count -gt 0) {
            $rendered = "$Command " + ($Arguments -join ' ')
        }

        if ($DryRun) {
            Write-IntegrationLog "[DRY RUN] $rendered"
            return @()
        }

        Write-IntegrationLog "Executing: $rendered"
        $output = & $Command @Arguments 2>&1
        $exitCode = $LASTEXITCODE
        if (-not $Quiet -and $output) {
            $output | ForEach-Object { Write-IntegrationLog "  $_" }
        }
        if ($exitCode -ne 0) {
            throw "Command '$rendered' failed with exit code $exitCode. Output:`n$($output -join [Environment]::NewLine)"
        }
        return $output
    }

    function Ensure-ToolInstalled {
        param([string]$Tool)
        if ($DryRun) {
            Write-IntegrationLog "[DRY RUN] Verifying tool '$Tool' is available."
            return
        }

        if (-not (Get-Command $Tool -ErrorAction SilentlyContinue)) {
            throw "Required tool '$Tool' was not found on PATH."
        }
    }

    Ensure-ToolInstalled -Tool 'git'
    Ensure-ToolInstalled -Tool 'gh'

    Write-IntegrationLog "Preparing integration branch '$IntegrationBranch' from '$BaseBranch'."
    Invoke-ExternalCommand -Command 'git' -Arguments @('fetch', 'origin', $BaseBranch)
    Invoke-ExternalCommand -Command 'git' -Arguments @('checkout', $BaseBranch)
    Invoke-ExternalCommand -Command 'git' -Arguments @('pull', 'origin', $BaseBranch)
    Invoke-ExternalCommand -Command 'git' -Arguments @('checkout', '-B', $IntegrationBranch, "origin/$BaseBranch")
    Invoke-ExternalCommand -Command 'git' -Arguments @('push', '-u', 'origin', $IntegrationBranch)

    Write-IntegrationLog "Retargeting pull requests to '$IntegrationBranch'."
    foreach ($pr in $PullRequestsToRetarget) {
        Invoke-ExternalCommand -Command 'gh' -Arguments @('pr', 'edit', $pr.ToString(), '--repo', $Repository, '--base', $IntegrationBranch)
    }

    Write-IntegrationLog "Merging pull requests into '$IntegrationBranch'."
    foreach ($pr in $PullRequestsMergeOrder) {
        Invoke-ExternalCommand -Command 'gh' -Arguments @('pr', 'merge', $pr.ToString(), '--repo', $Repository, '--merge', '--admin')
    }

    if (-not $DryRun) {
        Write-IntegrationLog "Waiting for CI to complete on '$IntegrationBranch'."
        $deadline = (Get-Date).AddMinutes($CiTimeoutMinutes)
        $ciResult = $null
        while ((Get-Date) -lt $deadline) {
            $runOutput = Invoke-ExternalCommand -Command 'gh' -Arguments @('run', 'list', '--repo', $Repository, '--branch', $IntegrationBranch, '--limit', '1', '--json', 'status,conclusion,workflowName,displayTitle,url') -Quiet
            $jsonText = ($runOutput -join [Environment]::NewLine).Trim()
            if ([string]::IsNullOrWhiteSpace($jsonText)) {
                Start-Sleep -Seconds $CiPollIntervalSeconds
                continue
            }

            try {
                $runs = $jsonText | ConvertFrom-Json
            }
            catch {
                throw "Failed to parse CI run JSON: $jsonText"
            }

            if ($runs.Count -eq 0) {
                Start-Sleep -Seconds $CiPollIntervalSeconds
                continue
            }

            $latestRun = $runs[0]
            if ($latestRun.status -eq 'completed') {
                $ciResult = $latestRun
                break
            }

            Start-Sleep -Seconds $CiPollIntervalSeconds
        }

        if (-not $ciResult) {
            throw "CI did not complete within $CiTimeoutMinutes minutes for branch '$IntegrationBranch'."
        }

        Write-IntegrationLog "CI result: status=$($ciResult.status) conclusion=$($ciResult.conclusion) workflow=$($ciResult.workflowName)"
    }
    else {
        $ciResult = [pscustomobject]@{
            status      = 'dry-run'
            conclusion  = 'dry-run'
            workflowName = 'dry-run'
            displayTitle = 'dry-run'
            url         = 'https://example.com/dry-run'
        }
    }

    $mergedChecklist = @()
    foreach ($pr in $PullRequestsMergeOrder) {
        $mergedChecklist += "- [x] PR #$pr"
    }

    $retargetOnly = @()
    foreach ($pr in $PullRequestsToRetarget) {
        if ($PullRequestsMergeOrder -notcontains $pr) {
            $retargetOnly += "- [ ] PR #$pr (retargeted only)"
        }
    }

    $ciChecklist = if ($ciResult.conclusion -eq 'success') {
        "- [x] CI status: success ($($ciResult.workflowName))"
    }
    else {
        "- [ ] CI status: $($ciResult.conclusion ?? $ciResult.status) ($($ciResult.workflowName))"
    }

    $bodyLines = @("## Summary")
    $bodyLines += ""
    $bodyLines += $mergedChecklist
    if ($retargetOnly.Count -gt 0) {
        $bodyLines += $retargetOnly
    }
    $bodyLines += ""
    $bodyLines += $ciChecklist
    $bodyLines += ""
    if ($ciResult.url) {
        $bodyLines += "CI run: $($ciResult.url)"
    }

    $prBody = $bodyLines -join [Environment]::NewLine

    Write-IntegrationLog "Creating summary pull request back to '$BaseBranch'."
    $prTitle = "Integration stack $SummaryLabel → $BaseBranch"
    $prArgs = @('pr', 'create', '--repo', $Repository, '--base', $BaseBranch, '--head', $IntegrationBranch, '--title', $prTitle, '--body', $prBody)
    Invoke-ExternalCommand -Command 'gh' -Arguments $prArgs

    Write-IntegrationLog "Integration stack completed successfully."
}
