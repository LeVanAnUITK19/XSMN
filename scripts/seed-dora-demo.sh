#!/usr/bin/env bash
# Seed DORA demo data into Pushgateway (mirrors historical numbers from DORA.md).
set -euo pipefail

PUSHGATEWAY_URL="${DORA_PUSHGATEWAY_URL:-http://localhost:9091}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOW="$(date +%s)"
WEEK_SEC=604800

echo "Seeding DORA demo metrics to ${PUSHGATEWAY_URL} ..."

# 22 successful deploys over the last 7 weeks (lead times in seconds)
LEAD_TIMES=(120 39 720 1200 360 420 540 600 480 300 180 900 240 360 540 600 480 720 300 540 420 360)
idx=0
for lead in "${LEAD_TIMES[@]}"; do
  idx=$((idx + 1))
  # Spread timestamps across ~7 weeks
  weeks_ago=$(( (idx % 7) ))
  ts=$(( NOW - weeks_ago * WEEK_SEC - idx * 3600 ))
  curl -fsS --data-binary @- \
    "${PUSHGATEWAY_URL%/}/metrics/job/xsmn-dora/instance/seed-success-${idx}" <<EOF
xsmn_dora_deployment_event{status="success",branch="main"} 1
xsmn_dora_lead_time_seconds ${lead}
xsmn_dora_deployment_timestamp_seconds ${ts}
EOF
done

# 2 failed deployments (Change Failure Rate demo)
for fail_idx in 1 2; do
  ts=$(( NOW - fail_idx * WEEK_SEC - 86400 ))
  curl -fsS --data-binary @- \
    "${PUSHGATEWAY_URL%/}/metrics/job/xsmn-dora/instance/seed-failure-${fail_idx}" <<EOF
xsmn_dora_deployment_event{status="failure",branch="main"} 1
xsmn_dora_deployment_timestamp_seconds ${ts}
EOF
done

# 2 recovery events (MTTR ~28 minutes = 1680 seconds)
for rec_idx in 1 2; do
  ts=$(( NOW - rec_idx * WEEK_SEC ))
  curl -fsS --data-binary @- \
    "${PUSHGATEWAY_URL%/}/metrics/job/xsmn-dora/instance/seed-recovery-${rec_idx}" <<EOF
xsmn_dora_recovery_event 1
xsmn_dora_recovery_time_seconds 1680
xsmn_dora_recovery_timestamp_seconds ${ts}
EOF
done

echo "Done. Seeded ${#LEAD_TIMES[@]} successes, 2 failures, 2 recoveries."
echo "Open Grafana DORA dashboard: http://localhost:3001 (admin/admin)"
