# Sync DORA metrics from real GitHub repo history → Pushgateway → Prometheus → Grafana.
# Instance labels: pr-<n>, run-<id>, pr-fail-<n>-<runId>, recovery-run-<id>, recovery-pr-fail-<n>-<runId>
#
# Requires: GITHUB_TOKEN (repo read) or `gh auth login`
#
# Usage:
#   powershell -File .\scripts\sync-dora-from-github.ps1 -ReplaceAll

param(
    [string]$Repo = "LeVanAnUITK19/XSMN",
    [string]$PushgatewayUrl = "http://localhost:9091",
    [string]$Token = $env:GITHUB_TOKEN,
    [switch]$ReplaceAll
)

$ErrorActionPreference = "Stop"

function Get-GitHubToken {
    if ($Token) { return $Token }
    $gh = Get-Command gh -ErrorAction SilentlyContinue
    if ($gh) {
        $t = gh auth token 2>$null
        if ($t) { return $t.Trim() }
    }
    throw "Can GITHUB_TOKEN. Tao PAT (scope repo) hoac chay: gh auth login"
}

function Get-AllPages {
    param([string]$FirstPath, [string]$AuthToken)
    $items = @()
    $path = $FirstPath
    while ($path) {
        $headers = @{
            Accept = "application/vnd.github+json"
            Authorization = "Bearer $AuthToken"
            "X-GitHub-Api-Version" = "2022-11-28"
        }
        $uri = if ($path -like "http*") { $path } else { "https://api.github.com$path" }
        $resp = Invoke-WebRequest -Uri $uri -Headers $headers -UseBasicParsing
        $page = $resp.Content | ConvertFrom-Json
        if ($page) { $items += @($page) }
        $link = $resp.Headers["Link"]
        $next = $null
        if ($link) {
            foreach ($part in ($link -split ",")) {
                if ($part -match 'rel="next"') {
                    $next = ($part -replace '<|>.*', "").Trim()
                }
            }
        }
        $path = $next
    }
    return $items
}

function Push-Metrics {
    param([string]$Instance, [string[]]$Lines)
    $body = ($Lines -join "`n") + "`n"
    $tmp = [IO.Path]::GetTempFileName()
    try {
        [IO.File]::WriteAllText($tmp, $body, [Text.UTF8Encoding]::new($false))
        curl.exe -fsS --data-binary "@$tmp" "$PushgatewayUrl/metrics/job/xsmn-dora/instance/$Instance" | Out-Null
    } finally {
        Remove-Item -Force $tmp -ErrorAction SilentlyContinue
    }
}

function To-UnixSeconds([string]$IsoDate) {
    return [int][DateTimeOffset]::Parse($IsoDate).ToUnixTimeSeconds()
}

function Push-FailureRun {
    param(
        $Run,
        [string]$Instance,
        [string]$Source,
        [hashtable]$PushedFailures,
        [string]$Branch = "main"
    )
    if ($PushedFailures.ContainsKey($Instance)) { return }
    $PushedFailures[$Instance] = $true
    $ts = To-UnixSeconds $Run.updated_at
    Push-Metrics -Instance $Instance -Lines @(
        '# TYPE xsmn_dora_deployment_event gauge'
        "xsmn_dora_deployment_event{status=`"failure`",branch=`"$Branch`",source=`"$Source`"} 1"
        '# TYPE xsmn_dora_deployment_timestamp_seconds gauge'
        "xsmn_dora_deployment_timestamp_seconds $ts"
    )
}

function Push-Recovery {
    param(
        [string]$Instance,
        [int]$MttrSeconds,
        [int]$RecoveryTs,
        [string]$Source = "github-actions"
    )
    if ($MttrSeconds -le 0) { return }
    Push-Metrics -Instance $Instance -Lines @(
        '# TYPE xsmn_dora_recovery_event gauge'
        "xsmn_dora_recovery_event{source=`"$Source`"} 1"
        '# TYPE xsmn_dora_recovery_time_seconds gauge'
        "xsmn_dora_recovery_time_seconds $MttrSeconds"
        '# TYPE xsmn_dora_recovery_timestamp_seconds gauge'
        "xsmn_dora_recovery_timestamp_seconds $RecoveryTs"
    )
}

$auth = Get-GitHubToken
Write-Host "Sync DORA tu GitHub repo: $Repo"
Write-Host "Pushgateway: $PushgatewayUrl"

if ($ReplaceAll) {
    Write-Host "Xoa metric cu (job xsmn-dora)..."
    curl.exe -fsS -X DELETE "$PushgatewayUrl/metrics/job/xsmn-dora" 2>$null
}

# --- Merged PRs to main = successful deployments ---
$prs = Get-AllPages -FirstPath "/repos/$Repo/pulls?state=closed&base=main&per_page=100&sort=updated&direction=desc" -AuthToken $auth
$merged = @($prs | Where-Object { $_.merged_at })
Write-Host "Merged PRs to main: $($merged.Count)"

foreach ($pr in $merged) {
    $leadSec = [int]([DateTimeOffset]::Parse($pr.merged_at) - [DateTimeOffset]::Parse($pr.created_at)).TotalSeconds
    if ($leadSec -lt 0) { $leadSec = 0 }
    $ts = To-UnixSeconds $pr.merged_at
    Push-Metrics -Instance "pr-$($pr.number)" -Lines @(
        '# TYPE xsmn_dora_deployment_event gauge'
        'xsmn_dora_deployment_event{status="success",branch="main",source="github-pr"} 1'
        '# TYPE xsmn_dora_lead_time_seconds gauge'
        "xsmn_dora_lead_time_seconds $leadSec"
        '# TYPE xsmn_dora_deployment_timestamp_seconds gauge'
        "xsmn_dora_deployment_timestamp_seconds $ts"
    )
}

# --- All workflow runs (paginated) ---
$runs = Get-AllPages -FirstPath "/repos/$Repo/actions/runs?per_page=100" -AuthToken $auth
Write-Host "Workflow runs fetched: $($runs.Count)"

$pushedFailures = @{}
$recoveryCount = 0

# Failed runs on main (push, pull_request, schedule, workflow_dispatch, ...)
$failedOnMain = @($runs | Where-Object {
    $_.conclusion -eq "failure" -and $_.head_branch -eq "main"
})
Write-Host "Failed runs on main (any event): $($failedOnMain.Count)"

foreach ($run in $failedOnMain) {
    Push-FailureRun -Run $run -Instance "run-$($run.id)" -Source "github-actions" -PushedFailures $pushedFailures
}

# Failed CI on merged PR branches (before merge) — aligns with DORA.md incidents on feature PRs
foreach ($pr in $merged) {
    $headSha = $pr.head.sha
    if (-not $headSha) { continue }
    $prRuns = Get-AllPages -FirstPath "/repos/$Repo/actions/runs?head_sha=$headSha&per_page=100" -AuthToken $auth
    $prFails = @($prRuns | Where-Object { $_.conclusion -eq "failure" })
    if ($prFails.Count -eq 0) { continue }

    $prBranch = if ($pr.head.ref) { $pr.head.ref } else { "pr-$($pr.number)" }
    $prSuccess = @($prRuns | Where-Object { $_.conclusion -eq "success" } |
        Sort-Object { [DateTimeOffset]::Parse($_.updated_at) })
    $mergedAt = [DateTimeOffset]::Parse($pr.merged_at)

    foreach ($fail in ($prFails | Sort-Object { [DateTimeOffset]::Parse($_.updated_at) })) {
        $inst = "pr-fail-$($pr.number)-$($fail.id)"
        Push-FailureRun -Run $fail -Instance $inst -Source "github-pr-ci" -PushedFailures $pushedFailures -Branch $prBranch

        $failTime = [DateTimeOffset]::Parse($fail.updated_at)
        $recovery = $prSuccess | Where-Object {
            [DateTimeOffset]::Parse($_.updated_at) -gt $failTime
        } | Select-Object -First 1

        if ($recovery) {
            $mttr = [int]([DateTimeOffset]::Parse($recovery.updated_at) - $failTime).TotalSeconds
            $ts = To-UnixSeconds $recovery.updated_at
        } elseif ($mergedAt -gt $failTime) {
            $mttr = [int]($mergedAt - $failTime).TotalSeconds
            $ts = To-UnixSeconds $pr.merged_at
        } else {
            continue
        }

        Push-Recovery -Instance "recovery-pr-fail-$($pr.number)-$($fail.id)" -MttrSeconds $mttr -RecoveryTs $ts -Source "github-pr-ci"
        $recoveryCount++
    }
}

# MTTR: failed run on main → next successful run on main
$succeededOnMain = @($runs | Where-Object {
    $_.conclusion -eq "success" -and $_.head_branch -eq "main"
} | Sort-Object { [DateTimeOffset]::Parse($_.updated_at) })

foreach ($fail in ($failedOnMain | Sort-Object { [DateTimeOffset]::Parse($_.updated_at) })) {
    $failTime = [DateTimeOffset]::Parse($fail.updated_at)
    $recovery = $succeededOnMain | Where-Object {
        [DateTimeOffset]::Parse($_.updated_at) -gt $failTime
    } | Select-Object -First 1
    if (-not $recovery) { continue }
    $mttr = [int]([DateTimeOffset]::Parse($recovery.updated_at) - $failTime).TotalSeconds
    if ($mttr -le 0) { continue }
    Push-Recovery -Instance "recovery-run-$($fail.id)" -MttrSeconds $mttr -RecoveryTs (To-UnixSeconds $recovery.updated_at)
    $recoveryCount++
}

$successCount = $merged.Count
$failCount = $pushedFailures.Count
$denom = [math]::Max($successCount, 1)
$cfr = if ($failCount -gt 0) { [math]::Round(100 * $failCount / $denom, 1) } else { 0 }

Write-Host ""
Write-Host "Done - du lieu THAT tu GitHub:"
Write-Host "  Deploy (merged PR): $successCount"
Write-Host "  Failed events:      $failCount (main + PR CI)"
Write-Host "  Recovery samples:   $recoveryCount"
Write-Host "  CFR (vs deploys):   $cfr %  (= failures / merged PRs, nhu DORA.md)"
Write-Host '  Instance labels:    pr-<n>, run-<id>, pr-fail-<n>-<runId>, recovery-*'
Write-Host ""
Write-Host 'Grafana: http://localhost:3001/d/xsmn-dora/xsmn-dora-metrics'
