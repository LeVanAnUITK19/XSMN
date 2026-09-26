#!/bin/sh
# entrypoint.sh - Inject env vars vào prometheus config rồi start Prometheus
set -e

SRC_CONFIG="/etc/prometheus/prometheus.yml"
WORK_CONFIG="/tmp/prometheus.yml"
TOKEN_FILE="/tmp/metrics_token"

# Copy config sang /tmp để có quyền write
cp "$SRC_CONFIG" "$WORK_CONFIG"

# ── 1. Inject BACKEND_TARGET ──────────────────────────────────────────────────
BACKEND_TARGET="${BACKEND_TARGET:-host.docker.internal:3000}"
sed -i "s|\${BACKEND_TARGET:-host.docker.internal:3000}|${BACKEND_TARGET}|g" "$WORK_CONFIG"

# ── 2. Tự động thêm scheme: https nếu là Render URL ──────────────────────────
if echo "$BACKEND_TARGET" | grep -q "\.onrender\.com"; then
  sed -i '/job_name.*xsmn-backend/a\    scheme: https' "$WORK_CONFIG"
fi

# ── 3. Inject METRICS_TOKEN nếu có ───────────────────────────────────────────
if [ -n "$METRICS_TOKEN" ]; then
  printf '%s' "$METRICS_TOKEN" > "$TOKEN_FILE"
  chmod 600 "$TOKEN_FILE"

  # Uncomment authorization block trong config
  sed -i 's/^    # authorization:/    authorization:/' "$WORK_CONFIG"
  sed -i "s|^    #   credentials_file:.*|      credentials_file: ${TOKEN_FILE}|" "$WORK_CONFIG"
fi

# ── 4. Start Prometheus với config đã inject ─────────────────────────────────
exec /bin/prometheus \
  --config.file="$WORK_CONFIG" \
  --storage.tsdb.path=/prometheus \
  --storage.tsdb.retention.time="${PROMETHEUS_RETENTION:-7d}" \
  --web.enable-lifecycle \
  --web.console.libraries=/usr/share/prometheus/console_libraries \
  --web.console.templates=/usr/share/prometheus/consoles
