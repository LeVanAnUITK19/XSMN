/**
 * schedulerAuth.js
 * Middleware bảo vệ API ghi kết quả (POST, PUT /api/results).
 * Chỉ cho phép scheduler hoặc internal service có token hợp lệ.
 *
 * Cách dùng:
 *   router.post('/', schedulerAuthMiddleware, createResult);
 *   router.put('/',  schedulerAuthMiddleware, saveResult);
 *
 * Token được cấu hình qua env var: SCHEDULER_API_TOKEN
 * Nếu không set → log cảnh báo nhưng vẫn cho phép (backward compat dev mode).
 * Trong production, PHẢI set SCHEDULER_API_TOKEN.
 */

export function schedulerAuthMiddleware(req, res, next) {
  const token = process.env.SCHEDULER_API_TOKEN;

  // Không có token configured → cho phép nhưng cảnh báo
  // (backward compatible với crawl/ scripts hiện tại)
  if (!token) {
    if (process.env.NODE_ENV === 'production') {
      console.warn('[AUTH] ⚠️  SCHEDULER_API_TOKEN không được set trong production!');
    }
    return next();
  }

  const authHeader = req.headers['authorization'] || '';
  const parts = authHeader.split(' ');

  // Kiểm tra format "Bearer <token>"
  if (parts.length !== 2 || parts[0] !== 'Bearer' || parts[1] !== token) {
    // Không log token, không expose chi tiết lỗi
    return res.status(401).json({ error: 'Unauthorized' });
  }

  next();
}
