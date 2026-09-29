/**
 * index.js — Entry point của Scheduler (Background Worker mode)
 *
 * Process chạy liên tục, KHÔNG tự exit.
 * Deploy trên Render như Background Worker — không scan port, không restart.
 *
 * Cơ chế:
 *   - Vòng lặp vô hạn kiểm tra giờ VN mỗi CHECK_INTERVAL_SECONDS
 *   - Nằm trong khung giờ → chạy job crawl
 *   - Ngoài khung giờ → ngủ đến lần tick tiếp theo
 *   - Sau khi crawl COMPLETE → ngủ đến đầu cửa sổ ngày hôm sau
 *
 * Chạy local (test nhanh):
 *   node src/index.js --once     → chạy một lần rồi exit (bypass time window)
 *   node src/index.js --date=2026-09-29 --once
 */

import { config, validateConfig } from './config.js';
validateConfig();

import { logger } from './utils/logger.js';
import { runUpdateJob } from './jobs/updateDailyResults.js';
import { sleep } from './utils/retry.js';

// ────────────────────────────────────────────────────────────────
// Parse CLI args
// ────────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
const overrideDate = args.find((a) => a.startsWith('--date='))?.split('=')[1] || null;
const runOnce      = args.includes('--once');

// ────────────────────────────────────────────────────────────────
// Helpers thời gian VN
// ────────────────────────────────────────────────────────────────

/** Trả về số phút từ 00:00 theo giờ VN hiện tại */
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

/** Parse "HH:MM" → số phút từ 00:00 */
function parseMinutes(timeStr) {
  const [hh, mm] = timeStr.split(':').map(Number);
  return hh * 60 + mm;
}

/** Ngày hôm nay theo giờ VN (YYYY-MM-DD) */
function getTodayVN() {
  return new Date().toLocaleDateString('sv-SE', {
    timeZone: 'Asia/Ho_Chi_Minh',
  });
}

/**
 * Tính ms cần ngủ để đến đầu cửa sổ làm việc ngày hôm sau.
 * Dùng khi job đã COMPLETE hoặc cửa sổ hôm nay đã qua.
 */
function msUntilNextWindowStart(windowStartMinutes) {
  const nowMinutes = getNowMinutesVN();
  // Phút còn lại đến nửa đêm + phút từ nửa đêm đến windowStart
  const minutesLeft = (24 * 60 - nowMinutes) + windowStartMinutes;
  return minutesLeft * 60 * 1000;
}

// ────────────────────────────────────────────────────────────────
// Main loop
// ────────────────────────────────────────────────────────────────
async function main() {
  logger.info('[SCHEDULER] ============================================');
  logger.info('[SCHEDULER] XSMN Scheduler khởi động (Background Worker)');
  logger.info('[SCHEDULER] ============================================', {
    date: overrideDate || '(hôm nay VN)',
    runOnce,
    windowStart: config.JOB_WINDOW_START,
    windowEnd:   config.JOB_WINDOW_END,
    checkIntervalSeconds: config.CHECK_INTERVAL_SECONDS,
  });

  // ── Chế độ --once: dùng để test, chạy xong exit ──────────────
  if (runOnce) {
    logger.info('[SCHEDULER] Chế độ --once: chạy một lần rồi thoát');
    const result = await runUpdateJob({ date: overrideDate });
    printSummary([result]);
    process.exit(result.action === 'FAILED' ? 1 : 0);
    return;
  }

  const windowStartMinutes = parseMinutes(config.JOB_WINDOW_START);
  const windowEndMinutes   = parseMinutes(config.JOB_WINDOW_END);
  const checkIntervalMs    = config.CHECK_INTERVAL_SECONDS * 1000;

  // Tracking theo ngày để tránh crawl lại sau khi đã COMPLETE
  let completedDate = null;

  // ── Vòng lặp vô hạn ──────────────────────────────────────────
  // eslint-disable-next-line no-constant-condition
  while (true) {
    const nowMinutes = getNowMinutesVN();
    const todayVN    = getTodayVN();

    const insideWindow = nowMinutes >= windowStartMinutes && nowMinutes <= windowEndMinutes;
    const alreadyDone  = completedDate === todayVN;

    if (!insideWindow) {
      // Ngoài khung giờ → tính thời gian ngủ thông minh
      let sleepMs;
      if (nowMinutes < windowStartMinutes) {
        // Chưa đến cửa sổ hôm nay → ngủ đến windowStart
        sleepMs = (windowStartMinutes - nowMinutes) * 60 * 1000;
        logger.info('[SCHEDULER] Chưa đến cửa sổ làm việc — ngủ đến windowStart', {
          windowStart: config.JOB_WINDOW_START,
          sleepMinutes: Math.ceil(sleepMs / 60000),
        });
      } else {
        // Đã qua cửa sổ hôm nay → ngủ đến cửa sổ ngày mai
        sleepMs = msUntilNextWindowStart(windowStartMinutes);
        logger.info('[SCHEDULER] Đã qua cửa sổ làm việc hôm nay — ngủ đến ngày mai', {
          windowStart: config.JOB_WINDOW_START,
          sleepHours: (sleepMs / 3600000).toFixed(1),
        });
        // Reset completedDate để sẵn sàng crawl ngày mới
        completedDate = null;
      }
      await sleep(sleepMs);
      continue;
    }

    if (alreadyDone) {
      // Đã crawl COMPLETE hôm nay → ngủ đến cửa sổ ngày mai
      const sleepMs = msUntilNextWindowStart(windowStartMinutes);
      logger.info('[SCHEDULER] Hôm nay đã COMPLETE — ngủ đến ngày mai', {
        completedDate,
        sleepHours: (sleepMs / 3600000).toFixed(1),
      });
      completedDate = null; // reset để ngày mới chạy lại
      await sleep(sleepMs);
      continue;
    }

    // ── Trong cửa sổ giờ và chưa COMPLETE → chạy job ────────────
    logger.info('[SCHEDULER] Trong cửa sổ làm việc — chạy job', {
      time: new Date().toLocaleTimeString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' }),
      date: todayVN,
    });

    const result = await runUpdateJob({ date: overrideDate || null });

    if (result.crawlStatus === 'COMPLETE') {
      logger.info('[SCHEDULER] Crawl COMPLETE ✅ — sẽ không chạy lại hôm nay', {
        date: todayVN,
        action: result.action,
      });
      completedDate = todayVN;
      // Ngủ đến cửa sổ ngày mai
      const sleepMs = msUntilNextWindowStart(windowStartMinutes);
      logger.info('[SCHEDULER] Ngủ đến cửa sổ ngày mai', {
        sleepHours: (sleepMs / 3600000).toFixed(1),
      });
      await sleep(sleepMs);
    } else {
      // INCOMPLETE / EMPTY / FAILED → thử lại sau CHECK_INTERVAL
      logger.info(`[SCHEDULER] Chưa COMPLETE (${result.crawlStatus}) — thử lại sau ${config.CHECK_INTERVAL_SECONDS}s`, {
        action: result.action,
        error:  result.error || undefined,
      });
      await sleep(checkIntervalMs);
    }
  }
}

function printSummary(results) {
  logger.info('[SCHEDULER] ============================================');
  logger.info('[SCHEDULER] FINAL SUMMARY');
  logger.info('[SCHEDULER] ============================================', {
    totalRuns:       results.length,
    created:         results.filter((r) => r.action === 'CREATED').length,
    updated:         results.filter((r) => r.action === 'UPDATED').length,
    skipped:         results.filter((r) => r.action === 'SKIPPED').length,
    failed:          results.filter((r) => r.action === 'FAILED').length,
    lastCrawlStatus: results.at(-1)?.crawlStatus || 'N/A',
  });
}

// ── Graceful shutdown ─────────────────────────────────────────────
// Background Worker nhận SIGTERM khi Render deploy mới hoặc restart
process.on('SIGTERM', () => {
  logger.info('[SCHEDULER] Nhận SIGTERM — dừng sau khi job hiện tại hoàn thành');
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('[SCHEDULER] Nhận SIGINT — dừng');
  process.exit(0);
});

main().catch((err) => {
  logger.error('[SCHEDULER] Lỗi không xử lý được', { error: err.message, stack: err.stack });
  process.exit(1);
});
