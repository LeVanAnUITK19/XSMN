#!/bin/sh
# entrypoint.sh cho Grafana
# Inject GF_PROMETHEUS_URL vào datasource config trước khi Grafana start.

set -e

DATASOURCE_FILE="/etc/grafana/provisioning/datasources/prometheus.yml"

# Thay placeholder ${GF_PROMETHEUS_URL} bằng giá trị thực từ env
# Default: http://prometheus:9090 (local Docker Compose)
PROMETHEUS_URL="${GF_PROMETHEUS_URL:-http://prometheus:9090}"

sed -i "s|\${GF_PROMETHEUS_URL}|${PROMETHEUS_URL}|g" "$DATASOURCE_FILE"

# Start Grafana bình thường
exec /run.sh
