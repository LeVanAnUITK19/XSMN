/**
 * crawlerAdapter.js
 * Tái sử dụng logic crawl từ crawl/crawlXSMN_PUT.js.
 * Adapter chuẩn hóa output và thêm validation.
 *
 * QUAN TRỌNG: File này KHÔNG import bất kỳ module nào từ crawl/
 * vì crawlXSMN_PUT.js là script chạy trực tiếp (gọi run() ngay lập tức).
 * Thay vào đó, ta extract lại hàm crawlXSMN core tại đây — giống hệt logic
 * gốc, KHÔNG thay đổi business logic.
 *
 * Khi Dockerfile build từ repo root, crawl/ được copy vào image.
 * Nếu muốn import trực tiếp trong tương lai, refactor crawl/crawlXSMN_PUT.js
 * để tách hàm crawlXSMN ra module riêng.
 */

import puppeteer from 'puppeteer';
import { logger } from '../utils/logger.js';
import { withRetry, RetryableError } from '../utils/retry.js';
import { config } from '../config.js';

// ────────────────────────────────────────────────────────────────
// Hằng số giải thưởng XSMN
// Dùng để validate kết quả đầy đủ
// ────────────────────────────────────────────────────────────────
export const PRIZE_COUNTS = {
  G8: 1,
  G7: 1,
  G6: 3,
  G5: 1,
  G4: 7,
  G3: 2,
  G2: 1,
  G1: 1,
  DB: 1,
};

export const TOTAL_PRIZES = Object.values(PRIZE_COUNTS).reduce((a, b) => a + b, 0); // 18

/**
 * Crawl kết quả XSMN từ minhngoc.net.vn — giống hệt logic trong crawl/
 *
 * @param {string} date - Format YYYY-MM-DD
 * @returns {{ date: string, region: string, provinces: Array }}
 */
async function crawlFromMinhNgoc(date) {
  const [y, m, d] = date.split('-');
  const targetDateStr = `${d}-${m}-${y}`;
  const url = `https://www.minhngoc.net.vn/ket-qua-xo-so/mien-nam/${targetDateStr}.html`;

  logger.info('[CRAWLER] Launching Puppeteer', { url });

  const browser = await puppeteer.launch({
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-blink-features=AutomationControlled',
      '--disable-dev-shm-usage',
      '--disable-gpu',
    ],
  });

  try {
    const page = await browser.newPage();

    // Ẩn dấu hiệu bot — giống crawler gốc
    await page.evaluateOnNewDocument(() => {
      Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
    });

    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
    );

    await page.setViewport({ width: 1280, height: 800 });

    await page.goto(url, {
      waitUntil: 'domcontentloaded',
      timeout: 60000,
    });

    // Chờ selector hoặc trả về rỗng nếu chưa có dữ liệu — giống crawler gốc
    try {
      await page.waitForSelector('.bkqmiennam', { timeout: 30000 });
      // Chờ thêm để page render đầy đủ
      await new Promise((r) => setTimeout(r, 3000));
    } catch (_) {
      logger.warn('[CRAWLER] Không tìm thấy .bkqmiennam — web chưa có dữ liệu hoặc bị block');
      await browser.close();
      return { date, region: 'mien-nam', provinces: [] };
    }

    // Parse kết quả — giống hệt logic crawler gốc
    const provinces = await page.evaluate((targetStr) => {
      const results = [];
      const webDateStr = targetStr.replace(/-/g, '/');
      const blocks = document.querySelectorAll('.bkqmiennam');

      blocks.forEach((block) => {
        const dateText = block.querySelector('.ngay')?.textContent.trim();
        if (!dateText || !dateText.includes(webDateStr)) return;

        const provinceTables = block.querySelectorAll('.bangketquaSo');

        provinceTables.forEach((table) => {
          const name = table.querySelector('.tinh a')?.textContent.trim();
          if (!name) return;

          const getValues = (className) => {
            const cells = table.querySelectorAll(`td.${className} .giaiSo`);
            return Array.from(cells)
              .map((el) => el.textContent.trim())
              .filter((v) => v !== '');
          };

          results.push({
            province: name,
            full: {
              G8: getValues('giai8'),
              G7: getValues('giai7'),
              G6: getValues('giai6'),
              G5: getValues('giai5'),
              G4: getValues('giai4'),
              G3: getValues('giai3'),
              G2: getValues('giai2'),
              G1: getValues('giai1'),
              DB: getValues('giaidb'),
            },
          });
        });
      });

      return results;
    }, targetDateStr);

    await browser.close();

    logger.info('[CRAWLER] Crawl hoàn thành', {
      date,
      provincesCount: provinces.length,
    });

    return { date, region: 'mien-nam', provinces };
  } catch (err) {
    await browser.close();
    throw new RetryableError(`Puppeteer error: ${err.message}`);
  }
}

/**
 * Crawl với retry.
 *
 * @param {string} date - YYYY-MM-DD
 */
export async function crawl(date) {
  return withRetry(
    async (attempt) => {
      logger.info(`[CRAWLER] Attempt ${attempt}`, { date });
      return crawlFromMinhNgoc(date);
    },
    {
      maxRetries: config.CRAWL_RETRY_LIMIT,
      baseDelayMs: 10000,
      label: `crawl(${date})`,
    }
  );
}
