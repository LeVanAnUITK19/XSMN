/**
 * retry.js
 * Retry có giới hạn với exponential backoff.
 * Không retry với lỗi xác thực (401, 403) hoặc lỗi cấu hình.
 */

import { logger } from './logger.js';

/**
 * Lỗi không cần retry (xác thực sai, cấu hình sai).
 */
export class FatalError extends Error {
  constructor(message) {
    super(message);
    this.name = 'FatalError';
  }
}

/**
 * Lỗi tạm thời — có thể retry.
 */
export class RetryableError extends Error {
  constructor(message, statusCode = null) {
    super(message);
    this.name = 'RetryableError';
    this.statusCode = statusCode;
  }
}

/**
 * Thực hiện fn với retry và exponential backoff.
 *
 * @param {Function} fn          - Async function cần retry
 * @param {number}   maxRetries  - Số lần retry tối đa
 * @param {number}   baseDelayMs - Delay cơ bản (ms), tăng theo 2^attempt
 * @param {string}   label       - Tên để log
 * @returns {*} Kết quả của fn nếu thành công
 * @throws {Error} Sau khi hết retry hoặc gặp FatalError
 */
export async function withRetry(fn, {
  maxRetries = 3,
  baseDelayMs = 5000,
  label = 'operation',
} = {}) {
  let lastError;

  for (let attempt = 1; attempt <= maxRetries + 1; attempt++) {
    try {
      return await fn(attempt);
    } catch (err) {
      lastError = err;

      // Không retry FatalError
      if (err instanceof FatalError) {
        logger.error(`[RETRY] ${label} — lỗi fatal, không retry`, {
          error: err.message,
        });
        throw err;
      }

      const isLastAttempt = attempt > maxRetries;

      if (isLastAttempt) {
        logger.error(`[RETRY] ${label} — thất bại sau ${maxRetries} lần retry`, {
          error: err.message,
        });
        throw err;
      }

      const delayMs = baseDelayMs * Math.pow(2, attempt - 1);
      logger.warn(`[RETRY] ${label} — lần ${attempt} thất bại, thử lại sau ${delayMs}ms`, {
        error: err.message,
        attempt,
        maxRetries,
      });

      await sleep(delayMs);
    }
  }

  throw lastError;
}

export const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
