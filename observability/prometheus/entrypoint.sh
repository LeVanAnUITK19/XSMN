#!/bin/sh
# entrypoint.sh
# Inject env vars vào prometheus.yml trước khi start Prometheus.
# Chạy khi container start — không chạy tay.

set -e

CONFIG="/etc/prometheus/prometheus.yml"

# ── 1. Inject BACKEND_TARGET ──────────────────────────────────────────────────
# BACKEND_TARGET có thể là:
#   Local:      host.docker.internal:3000
#   Render:     your-backend.onrender.com   (KHÔNG có http/https)
BACKEND_TARGET="${BACKEND_TARGET:-host.docker.internal:3000}"

sed -i "s|\${BACKEND_TARGET:-host.docker.internal:3000}|${BACKEND_TARGET}|g" "$CONFIG"

# ── 2. Tự động detect scheme (http vs https) ──────────────────────────────────
# Nếu target trông giống Render URL (*.onrender.com) → dùng https
# Nếu không → mặc định http (local)
if echo "$BACKEND_TARGET" | grep -q "\.onrender\.com"; then
  # Thêm scheme: https vào job config
  sed -i '/job_name.*xsmn-backend/a\    scheme: https' "$CONFIG"
fi

# ── 3. Inject METRICS_TOKEN nếu có ───────────────────────────────────────────
if [ -n "$METRICS_TOKEN" ]; then
  # Ghi token vào file (không echo ra log)
  printf '%s' "$METRICS_TOKEN" > /etc/prometheus/metrics_token
  chmod 600 /etc/prometheus/metrics_token

  # Uncomment authorization block trong config
  sed -i 's/^    # authorization:/    authorization:/' "$CONFIG"
  sed -i 's/^    #   credentials_file:/      credentials_file:/' "$CONFIG"
fi

# ── 4. Start Prometheus ───────────────────────────────────────────────────────
exec /bin/prometheus \
  --config.file="$CONFIG" \
  --storage.tsdb.path=/prometheus \
  --storage.tsdb.retention.time="${PROMETHEUS_RETENTION:-7d}" \
  --web.enable-lifecycle \
  --web.console.libraries=/usr/share/prometheus/console_libraries \
  --web.console.templates=/usr/share/prometheus/consoles
