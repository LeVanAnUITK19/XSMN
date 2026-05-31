#!/usr/bin/env bash
# Sync DORA metrics from real GitHub history (bash — CI/CD + Linux).
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-LeVanAnUITK19/XSMN}"
PUSHGATEWAY_URL="${DORA_PUSHGATEWAY_URL:-http://localhost:9091}"
TOKEN="${GITHUB_TOKEN:?GITHUB_TOKEN required}"
REPLACE_ALL=false

for arg in "$@"; do
  case "$arg" in
    --replace-all) REPLACE_ALL=true ;;
  esac
done

api() {
  curl -fsS -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com$1"
}

push_metrics() {
  local instance="$1"
  shift
  curl -fsS --data-binary @- \
    "${PUSHGATEWAY_URL%/}/metrics/job/xsmn-dora/instance/${instance}" <<< "$*"
}

to_unix() {
  date -d "$1" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "${1%%.*}Z" +%s
}

lead_seconds() {
  local created="$1" merged="$2"
  local c m
  c=$(to_unix "$created")
  m=$(to_unix "$merged")
  echo $((m - c))
}

echo "Sync DORA from ${REPO} → ${PUSHGATEWAY_URL}"

if [ "$REPLACE_ALL" = true ]; then
  curl -fsS -X DELETE "${PUSHGATEWAY_URL%/}/metrics/job/xsmn-dora" 2>/dev/null || true
fi

page=1
while true; do
  prs=$(api "/repos/${REPO}/pulls?state=closed&base=main&per_page=100&page=${page}")
  count=$(echo "$prs" | jq 'length')
  [ "$count" -eq 0 ] && break

  echo "$prs" | jq -c '.[] | select(.merged_at != null)' | while read -r pr; do
    num=$(echo "$pr" | jq -r '.number')
    created=$(echo "$pr" | jq -r '.created_at')
    merged=$(echo "$pr" | jq -r '.merged_at')
    lead=$(lead_seconds "$created" "$merged")
    ts=$(to_unix "$merged")
    push_metrics "pr-${num}" "$(cat <<EOF
# TYPE xsmn_dora_deployment_event gauge
xsmn_dora_deployment_event{status="success",branch="main",source="github-pr"} 1
# TYPE xsmn_dora_lead_time_seconds gauge
xsmn_dora_lead_time_seconds ${lead}
# TYPE xsmn_dora_deployment_timestamp_seconds gauge
xsmn_dora_deployment_timestamp_seconds ${ts}
EOF
)"
  done

  [ "$count" -lt 100 ] && break
  page=$((page + 1))
done

runs=$(api "/repos/${REPO}/actions/runs?branch=main&per_page=100")
echo "$runs" | jq -c '.workflow_runs[] | select(.conclusion=="failure" and .event=="push")' | while read -r run; do
  id=$(echo "$run" | jq -r '.id')
  updated=$(echo "$run" | jq -r '.updated_at')
  ts=$(to_unix "$updated")
  push_metrics "run-${id}" "$(cat <<EOF
# TYPE xsmn_dora_deployment_event gauge
xsmn_dora_deployment_event{status="failure",branch="main",source="github-actions"} 1
# TYPE xsmn_dora_deployment_timestamp_seconds gauge
xsmn_dora_deployment_timestamp_seconds ${ts}
EOF
)"
done

echo "DORA sync complete."
