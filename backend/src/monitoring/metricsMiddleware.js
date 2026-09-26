// ============================================================
// metricsMiddleware.js - Express middleware để đo HTTP metrics
//
// Giải pháp route normalization:
// Vì middleware chạy TRƯỚC khi Express resolve route,
// req.route?.path chưa có giá trị tại thời điểm req start.
// → Dùng res.on('finish') để lấy req.route.path sau khi
//   route handler đã chạy xong → đúng route pattern.
//
// Cách tránh high cardinality:
// - Lấy req.route.path (ví dụ: "/:id") kết hợp req.baseUrl
//   thay vì req.url hoặc req.path (là URL thực với :id đã điền)
// - Fallback về req.path (stripped query string) nếu route unknown
// - Tuyệt đối không dùng query string, không dùng body
// ============================================================
import {
  httpRequestsTotal,
  httpRequestDurationSeconds,
  httpRequestsInProgress,
  httpRequestSizeBytes,
  httpResponseSizeBytes,
  httpRequestBytesTotal,
  httpResponseBytesTotal,
} from './metrics.js';

/**
 * Normalize route để tránh high cardinality.
 * Express gắn req.route.path sau khi route handler match.
 * Kết hợp req.baseUrl + req.route.path để có full path.
 *
 * Ví dụ:
 *   baseUrl = "/api/results", route.path = "/:id"
 *   → "/api/results/:id"
 */
function normalizeRoute(req) {
  if (req.route && req.route.path) {
    const base = req.baseUrl || '';
    const routePath = req.route.path === '/' ? '' : req.route.path;
    return base + routePath || '/';
  }
  // Fallback: strip query string, dùng pathname thuần
  // Vẫn có thể có cardinality nếu path chứa dynamic segments
  // nhưng đây là trường hợp route không match (404, etc.)
  const rawPath = req.path || '/';
  return rawPath.split('?')[0];
}

/**
 * Middleware chính đo HTTP metrics.
 * Gắn vào app trước tất cả routes.
 * Không đếm GET /metrics vào HTTP stats thông thường.
 */
export function metricsMiddleware(req, res, next) {
  // Bỏ qua /metrics endpoint để không tự đếm scrape traffic
  if (req.path === '/metrics') {
    return next();
  }

  const startHrTime = process.hrtime.bigint();

  // Đo request size từ Content-Length header
  const reqContentLength = parseInt(req.headers['content-length'] || '0', 10);

  // Tăng in-progress gauge (route chưa biết lúc này, dùng placeholder)
  // → Update lại đúng route sau ở finish
  httpRequestsInProgress.inc({ method: req.method, route: 'pending' });

  res.on('finish', () => {
    // Lấy normalized route SAU KHI handler đã chạy
    const route = normalizeRoute(req);
    const method = req.method;
    const statusCode = String(res.statusCode);

    // Tính duration (nanoseconds → seconds)
    const durationNs = process.hrtime.bigint() - startHrTime;
    const durationSec = Number(durationNs) / 1e9;

    // Đo response size từ Content-Length response header
    const resContentLength = parseInt(res.getHeader('content-length') || '0', 10);

    // --- Counter: tổng requests ---
    httpRequestsTotal.inc({ method, route, status_code: statusCode });

    // --- Histogram: duration ---
    httpRequestDurationSeconds.observe({ method, route, status_code: statusCode }, durationSec);

    // --- Gauge: in-progress (giảm) ---
    // Giảm pending placeholder đã tăng lúc trước
    httpRequestsInProgress.dec({ method, route: 'pending' });

    // --- Histogram: request size ---
    if (reqContentLength > 0) {
      httpRequestSizeBytes.observe({ method, route }, reqContentLength);
      httpRequestBytesTotal.inc({ method, route }, reqContentLength);
    }

    // --- Histogram + Counter: response size ---
    if (resContentLength > 0) {
      httpResponseSizeBytes.observe({ method, route, status_code: statusCode }, resContentLength);
      httpResponseBytesTotal.inc({ method, route, status_code: statusCode }, resContentLength);
    }
  });

  next();
}

/**
 * Auth middleware bảo vệ /metrics endpoint.
 * Nếu METRICS_TOKEN không set → cho phép tất cả (dev mode).
 * Nếu có token → phải gửi đúng: Authorization: Bearer <token>
 */
export function metricsAuthMiddleware(req, res, next) {
  const token = process.env.METRICS_TOKEN;

  // Không có token configured → không bảo vệ (local dev)
  if (!token) {
    return next();
  }

  const authHeader = req.headers['authorization'] || '';
  const parts = authHeader.split(' ');

  // Kiểm tra format "Bearer <token>" và so sánh
  if (parts.length !== 2 || parts[0] !== 'Bearer' || parts[1] !== token) {
    // Không log token, không expose chi tiết
    return res.status(401).json({ error: 'Unauthorized' });
  }

  next();
}
