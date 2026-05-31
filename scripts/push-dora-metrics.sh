#!/usr/bin/env bash
# Push DORA metrics to Prometheus Pushgateway (called from CI/CD or demo scripts).
set -euo pipefail

ACTION="${1:?Usage: push-dora-metrics.sh deploy_success|deploy_failure|recovery}"
PUSHGATEWAY_URL="${DORA_PUSHGATEWAY_URL:-http://localhost:9091}"
INSTANCE="${DORA_INSTANCE:-${GITHUB_RUN_ID:-manual-$(date +%s)}}"
JOB="xsmn-dora"
BRANCH="${GITHUB_REF_NAME:-main}"

if [ -z "${DORA_PUSHGATEWAY_URL:-}" ]; then
  echo "DORA_PUSHGATEWAY_URL not set — skipping DORA metrics push."
  exit 0
fi

build_payload() {
  case "$ACTION" in
    deploy_success)
      LEAD_TIME="${LEAD_TIME_SECONDS:-0}"
      cat <<EOF
# HELP xsmn_dora_deployment_event Deployment event marker (value 1)
# TYPE xsmn_dora_deployment_event gauge
xsmn_dora_deployment_event{status="success",branch="${BRANCH}"} 1
# HELP xsmn_dora_lead_time_seconds Lead time from CI start to deploy (seconds)
# TYPE xsmn_dora_lead_time_seconds gauge
xsmn_dora_lead_time_seconds ${LEAD_TIME}
# HELP xsmn_dora_deployment_timestamp_seconds Unix time of deployment
# TYPE xsmn_dora_deployment_timestamp_seconds gauge
xsmn_dora_deployment_timestamp_seconds $(date +%s)
EOF
      ;;
    deploy_failure)
      cat <<EOF
# HELP xsmn_dora_deployment_event Deployment event marker (value 1)
# TYPE xsmn_dora_deployment_event gauge
xsmn_dora_deployment_event{status="failure",branch="${BRANCH}"} 1
# HELP xsmn_dora_deployment_timestamp_seconds Unix time of failed change
# TYPE xsmn_dora_deployment_timestamp_seconds gauge
xsmn_dora_deployment_timestamp_seconds $(date +%s)
EOF
      ;;
    recovery)
      MTTR="${MTTR_SECONDS:-0}"
      cat <<EOF
# HELP xsmn_dora_recovery_event Incident recovery marker (value 1)
# TYPE xsmn_dora_recovery_event gauge
xsmn_dora_recovery_event 1
# HELP xsmn_dora_recovery_time_seconds Mean time to restore for this incident (seconds)
# TYPE xsmn_dora_recovery_time_seconds gauge
xsmn_dora_recovery_time_seconds ${MTTR}
# HELP xsmn_dora_recovery_timestamp_seconds Unix time of recovery
# TYPE xsmn_dora_recovery_timestamp_seconds gauge
xsmn_dora_recovery_timestamp_seconds $(date +%s)
EOF
      ;;
    *)
      echo "Unknown action: $ACTION" >&2
      exit 1
      ;;
  esac
}

PAYLOAD="$(build_payload)"
curl -fsS --data-binary @- \
  "${PUSHGATEWAY_URL%/}/metrics/job/${JOB}/instance/${INSTANCE}" <<< "$PAYLOAD"

echo "DORA metrics pushed: action=${ACTION}, instance=${INSTANCE}"
