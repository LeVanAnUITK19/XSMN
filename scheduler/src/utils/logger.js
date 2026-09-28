/**
 * logger.js
 * Logger có cấu trúc, dễ đọc trên Render logs.
 * Không log token hoặc dữ liệu nhạy cảm.
 */

function timestamp() {
  // Render hiển thị UTC — dùng ISO để dễ trace
  return new Date().toISOString();
}

function fmt(level, message, meta = {}) {
  const metaStr = Object.keys(meta).length > 0
    ? ' ' + JSON.stringify(meta)
    : '';
  return `[${timestamp()}] [${level}] ${message}${metaStr}`;
}

export const logger = {
  info: (message, meta = {}) => console.log(fmt('INFO ', message, meta)),
  warn: (message, meta = {}) => console.warn(fmt('WARN ', message, meta)),
  error: (message, meta = {}) => console.error(fmt('ERROR', message, meta)),
  debug: (message, meta = {}) => {
    if (process.env.NODE_ENV !== 'production') {
      console.log(fmt('DEBUG', message, meta));
    }
  },
};
