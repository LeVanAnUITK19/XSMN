# Seed DORA demo data into Pushgateway (mirrors DORA.md historical numbers).
param(
    [string]$PushgatewayUrl = "http://localhost:9091"
)

$now = [int][double]::Parse((Get-Date -UFormat %s))
$weekSec = 604800
$leadTimes = @(120, 39, 720, 1200, 360, 420, 540, 600, 480, 300, 180, 900, 240, 360, 540, 600, 480, 720, 300, 540, 420, 360)

function Push-Metrics {
    param([string]$Instance, [string[]]$Lines)
    $body = ($Lines -join "`n") + "`n"
    $tmp = [System.IO.Path]::GetTempFileName()
    try {
        [System.IO.File]::WriteAllText($tmp, $body, [System.Text.UTF8Encoding]::new($false))
        curl.exe -fsS --data-binary "@$tmp" "$PushgatewayUrl/metrics/job/xsmn-dora/instance/$Instance" | Out-Null
    } finally {
        Remove-Item -Force $tmp -ErrorAction SilentlyContinue
    }
}

Write-Host "Seeding DORA demo metrics to $PushgatewayUrl ..."

$idx = 0
foreach ($lead in $leadTimes) {
    $idx++
    $weeksAgo = $idx % 7
    $ts = $now - ($weeksAgo * $weekSec) - ($idx * 3600)
    Push-Metrics -Instance "seed-success-$idx" -Lines @(
        '# TYPE xsmn_dora_deployment_event gauge'
        'xsmn_dora_deployment_event{status="success",branch="main"} 1'
        '# TYPE xsmn_dora_lead_time_seconds gauge'
        "xsmn_dora_lead_time_seconds $lead"
        '# TYPE xsmn_dora_deployment_timestamp_seconds gauge'
        "xsmn_dora_deployment_timestamp_seconds $ts"
    )
}

foreach ($failIdx in 1..2) {
    $ts = $now - ($failIdx * $weekSec) - 86400
    Push-Metrics -Instance "seed-failure-$failIdx" -Lines @(
        '# TYPE xsmn_dora_deployment_event gauge'
        'xsmn_dora_deployment_event{status="failure",branch="main"} 1'
        '# TYPE xsmn_dora_deployment_timestamp_seconds gauge'
        "xsmn_dora_deployment_timestamp_seconds $ts"
    )
}

foreach ($recIdx in 1..2) {
    $ts = $now - ($recIdx * $weekSec)
    Push-Metrics -Instance "seed-recovery-$recIdx" -Lines @(
        '# TYPE xsmn_dora_recovery_event gauge'
        'xsmn_dora_recovery_event 1'
        '# TYPE xsmn_dora_recovery_time_seconds gauge'
        'xsmn_dora_recovery_time_seconds 1680'
        '# TYPE xsmn_dora_recovery_timestamp_seconds gauge'
        "xsmn_dora_recovery_timestamp_seconds $ts"
    )
}

Write-Host "Done. Open Grafana: http://localhost:3001 (admin/admin) -> XSMN DORA Metrics"
