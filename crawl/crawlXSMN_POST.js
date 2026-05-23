import puppeteer from "puppeteer";

const API_URL = process.env.API_URL || "https://xsmn.onrender.com/api/results";
const HEALTH_URL = API_URL.replace("/results", "/results/health");

const sleep = (ms) => new Promise(r => setTimeout(r, ms));

// Fix 1: Đánh thức Render trước khi crawl (tránh cold start timeout)
const warmUpRender = async () => {
  console.log("🔥 Warming up Render server...");
  try {
    await fetch(HEALTH_URL);
    console.log("✅ Render is awake");
  } catch (_) {
    console.log("⏳ Render đang thức dậy, chờ 30s...");
  }
  await sleep(30000);
};

const crawlXSMN = async (date) => {
  const [y, m, d] = date.split("-");
  const targetDateStr = `${d}-${m}-${y}`;
  const url = `https://www.minhngoc.net.vn/ket-qua-xo-so/mien-nam/${targetDateStr}.html`;

  const browser = await puppeteer.launch({
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      // Fix 2: Ẩn dấu hiệu bot để tránh bị website block
      '--disable-blink-features=AutomationControlled',
      '--disable-dev-shm-usage',
      '--disable-gpu',
    ],
  });

  const page = await browser.newPage();

  // Fix 2: Giả lập trình duyệt thật hơn
  await page.evaluateOnNewDocument(() => {
    Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
  });

  await page.setUserAgent(
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
  );

  await page.setViewport({ width: 1280, height: 800 });

  console.log("👉 Crawling:", url);

  await page.goto(url, { waitUntil: "domcontentloaded", timeout: 60000 });

  // Fix 3: Không crash khi web chưa có dữ liệu — trả về mảng rỗng
  try {
    await page.waitForSelector(".bkqmiennam", { timeout: 30000 });
    await sleep(3000);
  } catch (_) {
    console.log("⚠️ Không tìm thấy .bkqmiennam — web chưa có dữ liệu hoặc bị block");
    await browser.close();
    return { date, region: "mien-nam", provinces: [] };
  }

  const provinces = await page.evaluate((targetStr) => {
    const results = [];
    const webDateStr = targetStr.replace(/-/g, '/');

    const blocks = document.querySelectorAll(".bkqmiennam");

    blocks.forEach((block) => {
      const dateText = block.querySelector(".ngay")?.textContent.trim();
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

  return { date, region: "mien-nam", provinces };
};

// Fix 4: Tăng retry lên 5 lần, chờ 30s giữa các lần (đủ cho Render cold start)
const sendToAPI = async (data) => {
  for (let i = 1; i <= 5; i++) {
    try {
      console.log(`🚀 Send attempt ${i}/5`);

      const res = await fetch(API_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
        signal: AbortSignal.timeout(30000), // timeout 30s mỗi request
      });

      const text = await res.text();
      console.log("Response:", text);

      if (res.ok) {
        console.log("✅ SUCCESS");
        return;
      }
      console.log(`⚠️ Server trả về ${res.status}`);
    } catch (err) {
      console.log("❌ Error:", err.message);
    }

    if (i < 5) {
      console.log("⏳ Retry in 30s...");
      await sleep(30000);
    }
  }

  throw new Error("❌ Failed after 5 retries");
};

const run = async () => {
  try {
    const date = new Date().toLocaleDateString("sv-SE");
    console.log("📅 Crawling date:", date);

    // Đánh thức Render trước
    await warmUpRender();

    const data = await crawlXSMN(date);
    console.log(`📊 Crawled ${data.provinces.length} province(s)`);

    // Nếu chưa có dữ liệu → gửi placeholder để hiển thị "Đang cập nhật"
    if (!data.provinces.length) {
      data.provinces.push({
        province: "Đang cập nhật",
        full: { G8:["Chờ"], G7:["Chờ"], G6:["Chờ"], G5:["Chờ"], G4:["Chờ"], G3:["Chờ"], G2:["Chờ"], G1:["Chờ"], DB:["Chờ"] }
      });
    }

    await sendToAPI(data);

  } catch (err) {
    console.error("🔥 FINAL ERROR:", err.message);
    process.exit(1);
  }
};

run();
