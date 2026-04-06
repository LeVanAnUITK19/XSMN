import puppeteer from "puppeteer";
import dotenv from 'dotenv';
dotenv.config();

export const crawlXSMN = async (date) => {
  if (!date) throw new Error("Missing date");

  // Format date để khớp với URL và text trên web Minh Ngọc (dd-mm-yyyy)
  const [y, m, d] = date.split("-");
  const targetDateStr = `${d}-${m}-${y}`;
  const url = `https://www.minhngoc.net.vn/ket-qua-xo-so/mien-nam/${targetDateStr}.html`;

  const browser = await puppeteer.launch({
    headless: false,
    executablePath: '/opt/render/.cache/puppeteer/chrome/linux-146.0.7680.153/chrome-linux64/chrome',
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  const page = await browser.newPage();

  // 👉 GIẢ LẬP TRÌNH DUYỆT THẬT (Tránh bị chặn/timeout)
  await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

  try {
    console.log(`Đang truy cập: ${url}`);
    await page.goto(url, { waitUntil: "networkidle2", timeout: 60000 });

    // Đợi bảng kết quả xuất hiện
    await page.waitForSelector(".bkqmiennam", { timeout: 15000 });

    const provinces = await page.evaluate((targetStr) => {
      const results = [];
      // Web dùng dấu / (31/03/2026), biến truyền vào dùng dấu - (31-03-2026)
      const webDateStr = targetStr.replace(/-/g, '/');

      const blocks = document.querySelectorAll(".bkqmiennam");

      blocks.forEach((block) => {
        const dateText = block.querySelector(".ngay")?.textContent.trim();

        // Chỉ lấy block có ngày khớp với ngày cần crawl
        if (!dateText || !dateText.includes(webDateStr)) return;

        const provinceTables = block.querySelectorAll(".bangketquaSo");

        provinceTables.forEach((table) => {
          const name = table.querySelector(".tinh a")?.textContent.trim();
          if (!name) return;

          const getValues = (className) => {
            const cells = table.querySelectorAll(`td.${className} .giaiSo`);
            return Array.from(cells).map(el => el.textContent.trim()).filter(v => v !== "");
          };

          results.push({
            province: name,
            full: {
              G8: getValues("giai8"),
              G7: getValues("giai7"),
              G6: getValues("giai6"),
              G5: getValues("giai5"),
              G4: getValues("giai4"),
              G3: getValues("giai3"),
              G2: getValues("giai2"),
              G1: getValues("giai1"),
              DB: getValues("giaidb"),
            }
          });
        });
      });
      return results;
    }, targetDateStr);

    await browser.close();

    // 👉 SỬA LỖI LỆCH NGÀY: Tạo Date object dựa trên local time
    // date truyền vào là "2026-03-31" -> Y=2026, M=03, D=31
    const [year, month, day] = date.split("-").map(Number);

    // Lưu ý: Tháng trong JS bắt đầu từ 0 (Tháng 1 là 0, tháng 3 là 2)
    const localDate = new Date(year, month - 1, day);

    return {
      date: localDate,
      region: "mien-nam",
      provinces,
    };

  } catch (error) {
    if (browser) await browser.close();
    console.error("CRAWL ERROR:", error.message);
    return { date: null, region: "mien-nam", provinces: [] };
  }
};