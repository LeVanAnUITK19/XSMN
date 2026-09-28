/**
 * index.js — Entry point của Scheduler
 *
 * Render Cron Job khởi chạy file này theo lịch cấu hình.
 * Scheduler thực hiện các lượt kiểm tra trong cửa sổ thời gian,
 * rồi tự kết thúc khi hoàn thành hoặc hết giờ.
 *
 * Không có vòng lặp vô hạn, không giữ process sống vô thời hạn.
 *
 * Cách chạy:
 *   node src/index.js                    → chạy theo cửa sổ thời gian cấu hình
 *   node src/index.js --date=2026-09-28  → override ngày
 *   node src/index.js --once             → chạy một lần và thoát (để test)
 */

import { config, validateConfig } from './config.js';
validateConfig(); // Kiểm tra env vars bắt buộc — thoát nếu thiếu
import { logger } from './utils/logger.js';
import { runUpdateJob } from './jobs/updateDailyResults.js';
import { sleep } from './utils/retry.js';

// ────────────────────────────────────────────────────────────────
// Parse CLI args
// ────────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
const overrideDate = args.find((a) => a.startsWith('--date='))?.split('=')[1] || null;
const runOnce = args.includes('--once');

// ────────────────────────────────────────────────────────────────
// Parse thời gian từ chuỗi HH:MM (VN timezone)
// ────────────────────────────────────────────────────────────────
function parseWindowTime(timeStr) {
  const [hh, mm] = timeStr.split(':').map(Number);
  return { hh, mm };
}

/**
 * Lấy thời gian VN hiện tại dưới dạng số phút từ 00:00.
 */
function getNowMinutesVN() {
  const vnTime = new Date().toLocaleTimeString('sv-SE', {
    timeZone: 'Asia/Ho_Chi_Minh',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  });
  const [hh, mm] = vnTime.split(':').map(Number);
  return hh * 60 + mm;
}

/**
 * Chờ đến cửa sổ thời gian nếu chạy quá sớm.
 */
async function waitForWindow(windowStartMinutes) {
  const nowMinutes = getNowMinutesVN();
  if (nowMinutes >= windowStartMinutes) return;

  const waitMs = (windowStartMinutes - nowMinutes) * 60 * 1000;
  const waitMins = Math.ceil(waitMs / 60000);
  logger.info(`[SCHEDULER] Chờ ${waitMins} phút đến cửa sổ làm việc...`);
  await sleep(waitMs);
}

// ────────────────────────────────────────────────────────────────
// Main
// ────────────────────────────────────────────────────────────────
async function main() {
  logger.info('[SCHEDULER] ============================================');
  logger.info('[SCHEDULER] XSMN Scheduler khởi động');
  logger.info('[SCHEDULER] ============================================', {
    date: overrideDate || '(hôm nay VN)',
    runOnce,
    windowStart: config.JOB_WINDOW_START,
    windowEnd: config.JOB_WINDOW_END,
    checkIntervalSeconds: config.CHECK_INTERVAL_SECONDS,
  });

  const windowStart = parseWindowTime(config.JOB_WINDOW_START);
  const windowEnd = parseWindowTime(config.JOB_WINDOW_END);
  const windowStartMinutes = windowStart.hh * 60 + windowStart.mm;
  const windowEndMinutes = windowEnd.hh * 60 + windowEnd.mm;
  const checkIntervalMs = config.CHECK_INTERVAL_SECONDS * 1000;

  // Tracking summary
  let totalRuns = 0;
  let created = 0;
  let updated = 0;
  let skipped = 0;
  let failed = 0;
  let lastStatus = null;
  const schedulerStart = Date.now();

  // Nếu --once: chạy một lần và thoát ngay (dùng để test)
  if (runOnce) {
    logger.info('[SCHEDULER] Chế độ --once: chạy một lần và thoát');
    const result = await runUpdateJob({ date: overrideDate });
    printFinalSummary([result], Date.now() - schedulerStart);
    process.exit(result.action === 'FAILED' ? 1 : 0);
    return;
  }

  // Chờ đến cửa sổ nếu cần (khi chạy thủ công sớm hơn lịch)
  if (!overrideDate) {
    await waitForWindow(windowStartMinutes);
  }

  const allResults = [];

  // Vòng lặp trong cửa sổ thời gian
  // eslint-disable-next-line no-constant-condition
  while (true) {
    const nowMinutes = getNowMinutesVN();

    // Hết cửa sổ thời gian → kết thúc
    if (!overrideDate && nowMinutes > windowEndMinutes) {
      logger.info('[SCHEDULER] Hết cửa sổ thời gian làm việc — kết thúc');
      break;
    }

    totalRuns++;
    logger.info(`[SCHEDULER] --- Lượt kiểm tra #${totalRuns} ---`);

    const result = await runUpdateJob({ date: overrideDate });
    allResults.push(result);
    lastStatus = result.crawlStatus;

    switch (result.action) {
      case 'CREATED': created++; break;
      case 'UPDATED': updated++; break;
      case 'SKIPPED': skipped++; break;
      case 'FAILED':  failed++;  break;
    }

    // Nếu kết quả đã COMPLETE → kết thúc sớm
    if (result.crawlStatus === 'COMPLETE') {
      logger.info('[SCHEDULER] Kết quả đã COMPLETE — kết thúc sớm ✅');
      break;
    }

    // Override date thì chỉ cần chạy một lần
    if (overrideDate) {
      logger.info('[SCHEDULER] Override date mode — kết thúc sau một lượt');
      break;
    }

    // Kiểm tra còn đủ thời gian cho lượt tiếp không
    const nowMinutesAfter = getNowMinutesVN();
    const remainingMs = (windowEndMinutes - nowMinutesAfter) * 60 * 1000;

    if (remainingMs <= checkIntervalMs) {
      logger.info('[SCHEDULER] Không đủ thời gian cho lượt tiếp theo — kết thúc');
      break;
    }

    logger.info(`[SCHEDULER] Chờ ${config.CHECK_INTERVAL_SECONDS}s trước lượt tiếp...`);
    await sleep(checkIntervalMs);
  }

  printFinalSummary(allResults, Date.now() - schedulerStart);

  // Exit code 1 nếu tất cả đều thất bại
  process.exit(failed > 0 && created === 0 && updated === 0 ? 1 : 0);
}

function printFinalSummary(results, durationMs) {
  const durationSec = Math.round(durationMs / 1000);
  logger.info('[SCHEDULER] ============================================');
  logger.info('[SCHEDULER] FINAL SUMMARY');
  logger.info('[SCHEDULER] ============================================', {
    totalRuns: results.length,
    created: results.filter((r) => r.action === 'CREATED').length,
    updated: results.filter((r) => r.action === 'UPDATED').length,
    skipped: results.filter((r) => r.action === 'SKIPPED').length,
    failed: results.filter((r) => r.action === 'FAILED').length,
    lastCrawlStatus: results[results.length - 1]?.crawlStatus || 'N/A',
    durationSec,
  });
}

main().catch((err) => {
  logger.error('[SCHEDULER] Lỗi không xử lý được', { error: err.message, stack: err.stack });
  process.exit(1);
});
