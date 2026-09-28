/**
 * config.js
 * Đọc và validate tất cả environment variables khi khởi động.
 * Nếu thiếu biến bắt buộc → báo lỗi rõ ràng và thoát.
 *
 * Validate chỉ chạy khi gọi validateConfig() — thường từ index.js.
 * Import config object thuần không gây side effect để test có thể import tự do.
 */

import dotenv from 'dotenv';
dotenv.config();

function optionalEnv(name, defaultVal) {
  return process.env[name] || defaultVal;
}

export const config = {
  // Môi trường
  NODE_ENV: optionalEnv('NODE_ENV', 'production'),

  // Backend API
  get BACKEND_BASE_URL() { return process.env.BACKEND_BASE_URL || ''; },
  get SCHEDULER_API_TOKEN() { return process.env.SCHEDULER_API_TOKEN || ''; },

  // HTTP settings
  get HTTP_TIMEOUT_MS() { return parseInt(process.env.HTTP_TIMEOUT_MS || '60000', 10); },

  // Crawl settings
  get CRAWL_RETRY_LIMIT() { return parseInt(process.env.CRAWL_RETRY_LIMIT || '3', 10); },

  // Cửa sổ thời gian làm việc (giờ Việt Nam, format HH:MM)
  get JOB_WINDOW_START() { return process.env.JOB_WINDOW_START || '16:05'; },
  get JOB_WINDOW_END() { return process.env.JOB_WINDOW_END || '17:30'; },

  // Khoảng cách giữa các lượt kiểm tra (giây)
  get CHECK_INTERVAL_SECONDS() { return parseInt(process.env.CHECK_INTERVAL_SECONDS || '300', 10); },

  // Timezone
  get TZ() { return process.env.TZ || 'Asia/Ho_Chi_Minh'; },

  // Region mặc định
  get REGION() { return process.env.REGION || 'mien-nam'; },
};

/**
 * Validate các biến bắt buộc.
 * Gọi từ index.js trước khi chạy job.
 * Tests KHÔNG gọi hàm này.
 */
export function validateConfig() {
  const required = ['BACKEND_BASE_URL', 'SCHEDULER_API_TOKEN'];
  const missing = required.filter((k) => !process.env[k]);

  if (missing.length > 0) {
    for (const key of missing) {
      console.error(`[CONFIG] ❌ Thiếu biến môi trường bắt buộc: ${key}`);
    }
    process.exit(1);
  }

  console.log('[CONFIG] ✅ Config loaded:', {
    NODE_ENV: config.NODE_ENV,
    BACKEND_BASE_URL: config.BACKEND_BASE_URL,
    SCHEDULER_API_TOKEN: config.SCHEDULER_API_TOKEN ? '***' : '(not set)',
    HTTP_TIMEOUT_MS: config.HTTP_TIMEOUT_MS,
    CRAWL_RETRY_LIMIT: config.CRAWL_RETRY_LIMIT,
    JOB_WINDOW_START: config.JOB_WINDOW_START,
    JOB_WINDOW_END: config.JOB_WINDOW_END,
    CHECK_INTERVAL_SECONDS: config.CHECK_INTERVAL_SECONDS,
    REGION: config.REGION,
  });
}
