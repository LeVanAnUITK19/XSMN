# Sync DORA metrics from real GitHub repo history → Pushgateway → Prometheus → Grafana.
# No seed/fake data. Instance labels: pr-<number>, run-<id>, recovery-run-<id>
#
# Requires: GITHUB_TOKEN (repo read) — create at GitHub → Settings → Developer settings → PAT
#           or: gh auth login then script reads token via `gh auth token`
#
# Usage:
#   $env:GITHUB_TOKEN = "ghp_..."
#   powershell -File .\scripts\sync-dora-from-github.ps1
#   powershell -File .\scripts\sync-dora-from-github.ps1 -ReplaceAll   # xoa metric cu truoc khi sync

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

function Invoke-GitHubApi {
    param([string]$Path, [string]$AuthToken)
    $headers = @{
        Accept = "application/vnd.github+json"
        Authorization = "Bearer $AuthToken"
        "X-GitHub-Api-Version" = "2022-11-28"
    }
    $uri = "https://api.github.com$Path"
    Invoke-RestMethod -Uri $uri -Headers $headers
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

# --- Failed CI/CD runs on main = change failures ---
$runs = Get-AllPages -FirstPath "/repos/$Repo/actions/runs?branch=main&per_page=100" -AuthToken $auth
$failedRuns = @($runs | Where-Object { $_.conclusion -eq "failure" -and $_.event -eq "push" })
Write-Host "Failed push runs on main: $($failedRuns.Count)"

foreach ($run in $failedRuns) {
    $ts = To-UnixSeconds $run.updated_at
    Push-Metrics -Instance "run-$($run.id)" -Lines @(
        '# TYPE xsmn_dora_deployment_event gauge'
        'xsmn_dora_deployment_event{status="failure",branch="main",source="github-actions"} 1'
        '# TYPE xsmn_dora_deployment_timestamp_seconds gauge'
        "xsmn_dora_deployment_timestamp_seconds $ts"
    )
}

# --- MTTR: failed run → next successful run on main ---
$succeededRuns = @($runs | Where-Object { $_.conclusion -eq "success" -and $_.event -eq "push" } |
    Sort-Object { [DateTimeOffset]::Parse($_.updated_at) })

foreach ($fail in ($failedRuns | Sort-Object { [DateTimeOffset]::Parse($_.updated_at) })) {
    $failTime = [DateTimeOffset]::Parse($fail.updated_at)
    $recovery = $succeededRuns | Where-Object {
        [DateTimeOffset]::Parse($_.updated_at) -gt $failTime
    } | Select-Object -First 1
    if (-not $recovery) { continue }
    $mttr = [int]([DateTimeOffset]::Parse($recovery.updated_at) - $failTime).TotalSeconds
    if ($mttr -le 0) { continue }
    $ts = To-UnixSeconds $recovery.updated_at
    Push-Metrics -Instance "recovery-run-$($fail.id)" -Lines @(
        '# TYPE xsmn_dora_recovery_event gauge'
        'xsmn_dora_recovery_event{source="github-actions"} 1'
        '# TYPE xsmn_dora_recovery_time_seconds gauge'
        "xsmn_dora_recovery_time_seconds $mttr"
        '# TYPE xsmn_dora_recovery_timestamp_seconds gauge'
        "xsmn_dora_recovery_timestamp_seconds $ts"
    )
}

$successCount = $merged.Count
$failCount = $failedRuns.Count
$cfr = if (($successCount + $failCount) -gt 0) { [math]::Round(100 * $failCount / ($successCount + $failCount), 1) } else { 0 }

Write-Host ""
Write-Host "Done - du lieu THAT tu GitHub:"
Write-Host "  Deploy (merged PR): $successCount"
Write-Host "  Failed runs:        $failCount"
Write-Host "  CFR (uoc tinh):     $cfr %"
Write-Host '  Instance labels:    pr-<number>, run-<id>, recovery-run-<id>'
Write-Host ""
Write-Host 'Grafana: http://localhost:3001/d/xsmn-dora/xsmn-dora-metrics'
