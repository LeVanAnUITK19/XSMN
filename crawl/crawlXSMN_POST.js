import puppeteer from "puppeteer";

const API_URL = "https://xsmn.onrender.com/api/results";

const sleep = (ms) => new Promise(r => setTimeout(r, ms));

const crawlXSMN = async (date) => {
  const [y, m, d] = date.split("-");
  const targetDateStr = `${d}-${m}-${y}`;
  const url = `https://www.minhngoc.net.vn/ket-qua-xo-so/mien-nam/${targetDateStr}.html`;

  const browser = await puppeteer.launch({
    headless: "new", // 🔥 GitHub Actions phải dùng cái này
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  const page = await browser.newPage();

  await page.setUserAgent(
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120 Safari/537.36'
  );

  console.log("👉 Crawling:", url);

  await page.goto(url, { waitUntil: "domcontentloaded", timeout: 60000 });

  await page.waitForSelector(".bkqmiennam", { timeout: 30000 });

  await sleep(3000); // 🔥 tránh DOM chưa render xong

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

  return {
    date,
    region: "mien-nam",
    provinces,
  };
};

// 👉 gửi API + retry (quan trọng vì Render sleep)
const sendToAPI = async (data) => {
  for (let i = 1; i <= 3; i++) {
    try {
      console.log(`🚀 Send attempt ${i}`);

      const res = await fetch(API_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(data),
      });

      const text = await res.text();
      console.log("Response:", text);

      if (res.ok) {
        console.log("✅ SUCCESS");
        return;
      }
    } catch (err) {
      console.log("❌ Error:", err.message);
    }

    console.log("⏳ Retry in 10s...");
    await sleep(10000);
  }

  throw new Error("❌ Failed after 3 retries");
};

// 👉 chạy main
const run = async () => {
  try {
    // 👉 lấy ngày hôm nay
    const date = new Date().toLocaleDateString("sv-SE");

    const data = await crawlXSMN(date);

    console.log("📊 Data:", JSON.stringify(data, null, 2));

    if (!data.provinces.length) {
      throw new Error("No data crawled");
    }

    await sendToAPI(data);

  } catch (err) {
    console.error("🔥 FINAL ERROR:", err.message);
    process.exit(1);
  }
};

run();