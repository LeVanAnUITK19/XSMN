#!/bin/sh
# entrypoint.sh cho Grafana
# Inject GF_PROMETHEUS_URL vào datasource config trước khi start.
set -e

SRC="/etc/grafana/provisioning/datasources/prometheus.yml"
WORK="/tmp/grafana-datasources"
WORK_FILE="$WORK/prometheus.yml"

# Tạo thư mục làm việc trong /tmp (có quyền write)
mkdir -p "$WORK"
cp "$SRC" "$WORK_FILE"

# Thay placeholder bằng giá trị thực
PROMETHEUS_URL="${GF_PROMETHEUS_URL:-http://prometheus:9090}"
sed -i "s|\${GF_PROMETHEUS_URL}|${PROMETHEUS_URL}|g" "$WORK_FILE"

# Override provisioning path sang /tmp
export GF_PATHS_PROVISIONING="/tmp/grafana-provisioning"
mkdir -p "$GF_PATHS_PROVISIONING/datasources"
mkdir -p "$GF_PATHS_PROVISIONING/dashboards"

# Copy file đã inject
cp "$WORK_FILE" "$GF_PATHS_PROVISIONING/datasources/prometheus.yml"

# Copy dashboard config (read-only, không cần inject)
cp /etc/grafana/provisioning/dashboards/dashboard.yml \
   "$GF_PATHS_PROVISIONING/dashboards/dashboard.yml"

# Start Grafana
exec /run.sh
