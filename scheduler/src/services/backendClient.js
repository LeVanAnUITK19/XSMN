/**
 * backendClient.js
 * HTTP client để giao tiếp với Backend API.
 * Xử lý authentication, retry, timeout và idempotency.
 */

import { config } from '../config.js';
import { logger } from '../utils/logger.js';
import { withRetry, FatalError, RetryableError, sleep } from '../utils/retry.js';

// ────────────────────────────────────────────────────────────────
// Helper: fetch với timeout
// ────────────────────────────────────────────────────────────────
async function fetchWithTimeout(url, options = {}) {
  const controller = new AbortController();
  const timeout = config.HTTP_TIMEOUT_MS;
  const timer = setTimeout(() => controller.abort(), timeout);

  try {
    const response = await fetch(url, {
      ...options,
      signal: controller.signal,
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${config.SCHEDULER_API_TOKEN}`,
        ...options.headers,
      },
    });
    return response;
  } finally {
    clearTimeout(timer);
  }
}

/**
 * Đánh thức Render backend (xử lý cold start trên Free tier).
 * Không throw nếu thất bại — chỉ cảnh báo.
 */
export async function warmUpBackend() {
  const healthUrl = `${config.BACKEND_BASE_URL}/api/results/health`;
  logger.info('[BACKEND] Warming up backend...', { url: healthUrl });

  try {
    const res = await fetchWithTimeout(healthUrl, { method: 'GET' });
    if (res.ok) {
      logger.info('[BACKEND] Backend is awake');
      return;
    }
  } catch (_) {
    // Cold start — chờ rồi tiếp tục
  }

  logger.warn('[BACKEND] Backend chưa sẵn sàng, chờ 30s cho cold start...');
  await sleep(30000);
}

/**
 * Lấy kết quả hiện có từ backend theo date + region.
 *
 * @param {string} date   - YYYY-MM-DD
 * @param {string} region - mien-nam | mien-trung | mien-bac
 * @returns {Object|null} - Kết quả hiện có hoặc null nếu chưa có
 */
export async function getExistingResult(date, region) {
  const url = `${config.BACKEND_BASE_URL}/api/results/filter?region=${region}&date=${date}`;

  try {
    const res = await fetchWithTimeout(url, { method: 'GET' });

    if (res.status === 404) return null;

    if (!res.ok) {
      const text = await res.text();
      throw new RetryableError(`GET failed: ${res.status} ${text}`, res.status);
    }

    const json = await res.json();
    // Backend trả về { data: [...], pagination: {...} }
    const items = json.data || [];
    return items.length > 0 ? items[0] : null;
  } catch (err) {
    if (err instanceof RetryableError || err instanceof FatalError) throw err;
    throw new RetryableError(`Network error on GET: ${err.message}`);
  }
}

/**
 * POST — tạo kết quả mới.
 * Nếu backend trả 409/500 do duplicate key → chuyển sang PUT.
 *
 * @param {{ date: string, region: string, provinces: Array }} data
 * @returns {{ action: 'CREATED'|'CONFLICT' }}
 */
export async function postResult(data) {
  const url = `${config.BACKEND_BASE_URL}/api/results`;
  logger.info('[BACKEND] POST /api/results', { date: data.date, region: data.region });

  return withRetry(
    async (attempt) => {
      logger.info(`[BACKEND] POST attempt ${attempt}`, { date: data.date });

      const res = await fetchWithTimeout(url, {
        method: 'POST',
        body: JSON.stringify(data),
      });

      if (res.status === 401 || res.status === 403) {
        const text = await res.text();
        throw new FatalError(`Authentication failed: ${res.status} ${text}`);
      }

      // Conflict (duplicate) → caller sẽ chuyển sang PUT
      if (res.status === 409 || res.status === 500) {
        const text = await res.text();
        if (text.includes('duplicate') || text.includes('E11000')) {
          logger.warn('[BACKEND] POST conflict — bản ghi đã tồn tại, chuyển sang PUT', { date: data.date });
          return { action: 'CONFLICT' };
        }
        throw new RetryableError(`POST server error: ${res.status} ${text}`, res.status);
      }

      if (res.status === 429) {
        throw new RetryableError('Rate limited (429)', 429);
      }

      if (!res.ok) {
        const text = await res.text();
        throw new RetryableError(`POST failed: ${res.status} ${text}`, res.status);
      }

      logger.info('[BACKEND] POST thành công', { date: data.date });
      return { action: 'CREATED' };
    },
    {
      maxRetries: config.CRAWL_RETRY_LIMIT,
      baseDelayMs: 5000,
      label: `POST result(${data.date})`,
    }
  );
}

/**
 * PUT — cập nhật kết quả hiện có (upsert).
 * Backend dùng saveResult service với updateOne upsert.
 *
 * @param {{ date: string, region: string, provinces: Array }} data
 * @returns {{ action: 'UPDATED' }}
 */
export async function putResult(data) {
  const url = `${config.BACKEND_BASE_URL}/api/results`;
  logger.info('[BACKEND] PUT /api/results', { date: data.date, region: data.region });

  return withRetry(
    async (attempt) => {
      logger.info(`[BACKEND] PUT attempt ${attempt}`, { date: data.date });

      const res = await fetchWithTimeout(url, {
        method: 'PUT',
        body: JSON.stringify(data),
      });

      if (res.status === 401 || res.status === 403) {
        const text = await res.text();
        throw new FatalError(`Authentication failed: ${res.status} ${text}`);
      }

      if (res.status === 429) {
        throw new RetryableError('Rate limited (429)', 429);
      }

      if (res.status >= 500) {
        const text = await res.text();
        throw new RetryableError(`PUT server error: ${res.status} ${text}`, res.status);
      }

      if (!res.ok) {
        const text = await res.text();
        throw new RetryableError(`PUT failed: ${res.status} ${text}`, res.status);
      }

      logger.info('[BACKEND] PUT thành công', { date: data.date });
      return { action: 'UPDATED' };
    },
    {
      maxRetries: config.CRAWL_RETRY_LIMIT,
      baseDelayMs: 5000,
      label: `PUT result(${data.date})`,
    }
  );
}
