/**
 * updateDailyResults.js
 * Job chính: crawl → validate → POST/PUT/SKIP kết quả hàng ngày.
 *
 * Luồng:
 *   1. Lấy ngày hiện tại theo giờ VN
 *   2. Warm up backend
 *   3. Crawl kết quả
 *   4. Kiểm tra kết quả hiện có
 *   5. POST nếu chưa tồn tại, PUT nếu đã có, SKIP nếu giống hệt
 *   6. Trả về summary
 */

import { crawl } from '../services/crawlerAdapter.js';
import {
  validateResult,
  isDataIdentical,
  mergePrizeFull,
} from '../services/resultValidator.js';
import {
  warmUpBackend,
  getExistingResult,
  postResult,
  putResult,
} from '../services/backendClient.js';
import { logger } from '../utils/logger.js';
import { FatalError } from '../utils/retry.js';
import { config } from '../config.js';

/**
 * Lấy ngày hiện tại theo múi giờ Việt Nam (YYYY-MM-DD).
 * TZ=Asia/Ho_Chi_Minh phải được set trong môi trường Render.
 */
function getTodayVN() {
  // Dùng toLocaleDateString với locale sv-SE để có format YYYY-MM-DD
  return new Date().toLocaleDateString('sv-SE', {
    timeZone: 'Asia/Ho_Chi_Minh',
  });
}

/**
 * Kiểm tra một bản ghi hiện có có đang COMPLETE chưa.
 */
function isExistingComplete(existing) {
  if (!existing || !existing.provinces || existing.provinces.length === 0) {
    return false;
  }
  const validation = validateResult(existing);
  return validation.status === 'COMPLETE';
}

/**
 * Chạy job cập nhật kết quả một lần.
 *
 * @param {Object} options
 * @param {string} [options.date]        - Override ngày (YYYY-MM-DD), mặc định = hôm nay VN
 * @param {boolean} [options.forceUpdate] - Bỏ qua skip khi data giống nhau
 * @returns {Promise<Object>} Summary của job
 */
export async function runUpdateJob({ date = null, forceUpdate = false } = {}) {
  const jobStart = Date.now();
  const targetDate = date || getTodayVN();
  const region = config.REGION;

  const summary = {
    date: targetDate,
    region,
    action: null,   // CREATED | UPDATED | SKIPPED | FAILED
    crawlStatus: null,  // COMPLETE | INCOMPLETE | EMPTY
    existingStatus: null,
    retryCount: 0,
    durationMs: 0,
    error: null,
  };

  logger.info('[JOB] ===== Bắt đầu updateDailyResults =====', {
    date: targetDate,
    region,
  });

  try {
    // ── Bước 1: Warm up backend ─────────────────────────────────
    await warmUpBackend();

    // ── Bước 2: Crawl kết quả ───────────────────────────────────
    logger.info('[JOB] Bắt đầu crawl', { date: targetDate });
    const crawlResult = await crawl(targetDate);

    // ── Bước 3: Validate crawl result ──────────────────────────
    const validation = validateResult(crawlResult);
    summary.crawlStatus = validation.status;

    logger.info('[JOB] Crawl hoàn thành', {
      date: targetDate,
      provincesCount: crawlResult.provinces.length,
      status: validation.status,
      summary: validation.summary,
    });

    if (crawlResult.provinces.length === 0) {
      logger.warn('[JOB] Không có dữ liệu từ crawler — bỏ qua lần này');
      summary.action = 'SKIPPED';
      summary.error = 'Crawler trả về rỗng';
      return finalize(summary, jobStart);
    }

    // ── Bước 4: Lấy kết quả hiện có ────────────────────────────
    logger.info('[JOB] Kiểm tra kết quả hiện có trong DB', { date: targetDate, region });
    const existing = await getExistingResult(targetDate, region);
    const existingComplete = isExistingComplete(existing);
    summary.existingStatus = existing
      ? existingComplete ? 'COMPLETE' : 'INCOMPLETE'
      : 'NOT_FOUND';

    logger.info('[JOB] Trạng thái kết quả hiện có', {
      found: !!existing,
      status: summary.existingStatus,
    });

    // ── Bước 5: Bảo vệ — không ghi đè COMPLETE bằng INCOMPLETE ─
    if (existingComplete && validation.status === 'INCOMPLETE') {
      logger.info('[JOB] Kết quả hiện có đã COMPLETE, dữ liệu mới INCOMPLETE — SKIP', {
        date: targetDate,
      });
      summary.action = 'SKIPPED';
      return finalize(summary, jobStart);
    }

    // ── Bước 6: Chuẩn bị payload ────────────────────────────────
    // Nếu đã có kết quả, merge để không mất giải hợp lệ
    let finalProvinces = crawlResult.provinces;

    if (existing && existing.provinces && existing.provinces.length > 0) {
      finalProvinces = mergeProvinces(existing.provinces, crawlResult.provinces);
    }

    const payload = {
      date: targetDate,
      region,
      provinces: finalProvinces,
    };

    // ── Bước 7: Kiểm tra data có thay đổi không ────────────────
    if (!forceUpdate && existing) {
      if (isDataIdentical(existing.provinces || [], finalProvinces)) {
        logger.info('[JOB] Dữ liệu không thay đổi — SKIP', { date: targetDate });
        summary.action = 'SKIPPED';
        return finalize(summary, jobStart);
      }
    }

    // ── Bước 8: POST hoặc PUT ───────────────────────────────────
    if (!existing) {
      // Chưa tồn tại → POST
      logger.info('[JOB] Chưa có kết quả → POST', { date: targetDate });
      const result = await postResult(payload);

      if (result.action === 'CONFLICT') {
        // Race condition: vừa được tạo bởi instance khác → PUT
        logger.warn('[JOB] POST conflict — chuyển sang PUT', { date: targetDate });
        await putResult(payload);
        summary.action = 'UPDATED';
      } else {
        summary.action = 'CREATED';
      }
    } else {
      // Đã tồn tại → PUT
      logger.info('[JOB] Đã có kết quả → PUT', { date: targetDate });
      await putResult(payload);
      summary.action = 'UPDATED';
    }

    // ── Log chi tiết từng tỉnh ──────────────────────────────────
    for (const detail of validation.details) {
      logger.info(`[JOB] Tỉnh: ${detail.province}`, {
        isComplete: detail.isComplete,
        totalPrizes: detail.totalPrizes,
        missingPrizes: detail.missingPrizes,
      });
    }

    return finalize(summary, jobStart);
  } catch (err) {
    summary.action = 'FAILED';
    summary.error = err.message;

    if (err instanceof FatalError) {
      logger.error('[JOB] Lỗi fatal — không retry', { error: err.message });
    } else {
      logger.error('[JOB] Lỗi không mong đợi', { error: err.message });
    }

    return finalize(summary, jobStart);
  }
}

/**
 * Merge provinces: giữ lại giải hợp lệ từ existing khi incoming thiếu.
 */
function mergeProvinces(existingProvinces, incomingProvinces) {
  // Đảm bảo tất cả tỉnh trong incoming được xử lý
  const merged = [];

  // Tạo map từ existing
  const existingMap = new Map(
    existingProvinces.map((p) => [p.province, p])
  );

  for (const incoming of incomingProvinces) {
    const existing = existingMap.get(incoming.province);

    if (existing && existing.full) {
      merged.push({
        province: incoming.province,
        full: mergePrizeFull(existing.full, incoming.full),
      });
    } else {
      merged.push(incoming);
    }
  }

  return merged;
}

/**
 * Finalize summary và log kết quả.
 */
function finalize(summary, jobStart) {
  summary.durationMs = Date.now() - jobStart;

  logger.info('[JOB] ===== Kết thúc updateDailyResults =====', {
    date: summary.date,
    action: summary.action,
    crawlStatus: summary.crawlStatus,
    existingStatus: summary.existingStatus,
    durationMs: summary.durationMs,
    error: summary.error || undefined,
  });

  return summary;
}
