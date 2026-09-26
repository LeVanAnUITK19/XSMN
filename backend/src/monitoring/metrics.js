// ============================================================
// metrics.js - Prometheus metrics registry & custom metrics
// Chỉ expose system + HTTP metrics. Không có business/DB/crawl.
// ============================================================
import client from 'prom-client';

// Registry riêng, không dùng default global registry
// để tránh conflict nếu có module khác dùng prom-client
const register = new client.Registry();

// Label mặc định gắn vào tất cả metrics
register.setDefaultLabels({ app: 'xsmn-backend' });

// Thu thập toàn bộ Node.js/process metrics mặc định:
// process_cpu_user_seconds_total, process_cpu_system_seconds_total
// process_resident_memory_bytes, process_virtual_memory_bytes
// nodejs_heap_size_total_bytes, nodejs_heap_size_used_bytes
// nodejs_external_memory_bytes, nodejs_eventloop_lag_seconds
// nodejs_active_handles_total, nodejs_active_requests_total
// nodejs_version_info, process_start_time_seconds
client.collectDefaultMetrics({ register });

// ------------------------------------------------------------------
// 1. HTTP request counter
// Labels: method, route (normalized), status_code
// ------------------------------------------------------------------
export const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register],
});

// ------------------------------------------------------------------
// 2. HTTP request duration histogram
// Dùng để tính: average, P50, P90, P95, P99
// ------------------------------------------------------------------
export const httpRequestDurationSeconds = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.05, 0.1, 0.25, 0.5, 1, 2, 5, 10],
  registers: [register],
});

// ------------------------------------------------------------------
// 3. Active (in-progress) HTTP requests
// Tăng khi bắt đầu, giảm khi kết thúc (kể cả lỗi)
// ------------------------------------------------------------------
export const httpRequestsInProgress = new client.Gauge({
  name: 'http_requests_in_progress',
  help: 'Number of HTTP requests currently being processed',
  labelNames: ['method', 'route'],
  registers: [register],
});

// ------------------------------------------------------------------
// 4. Request size (bytes) - đọc Content-Length header
// ------------------------------------------------------------------
export const httpRequestSizeBytes = new client.Histogram({
  name: 'http_request_size_bytes',
  help: 'HTTP request size in bytes (Content-Length)',
  labelNames: ['method', 'route'],
  buckets: [100, 500, 1000, 5000, 10000, 50000, 100000],
  registers: [register],
});

// ------------------------------------------------------------------
// 5. Response size (bytes) - đọc Content-Length response header
// ------------------------------------------------------------------
export const httpResponseSizeBytes = new client.Histogram({
  name: 'http_response_size_bytes',
  help: 'HTTP response size in bytes (Content-Length)',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [100, 500, 1000, 5000, 10000, 50000, 100000, 500000],
  registers: [register],
});

// ------------------------------------------------------------------
// 6. Traffic counters (bytes) - dùng để tính throughput (rate)
// ------------------------------------------------------------------
export const httpRequestBytesTotal = new client.Counter({
  name: 'http_request_bytes_total',
  help: 'Total bytes received in HTTP requests',
  labelNames: ['method', 'route'],
  registers: [register],
});

export const httpResponseBytesTotal = new client.Counter({
  name: 'http_response_bytes_total',
  help: 'Total bytes sent in HTTP responses',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register],
});

export default register;
