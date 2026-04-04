import puppeteer from "puppeteer";

export const crawlXSMN1 = async (date) => {
  if (!date) throw new Error("Missing date");

  const [y, m, d] = date.split("-");
  const targetDateSlash = `${d}/${m}/${y}`; // 02/04/2026
  const url = `https://xoso.com.vn/ket-qua-xo-so-mien-nam.html`;

  const browser = await puppeteer.launch({
    headless: "new",
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-blink-features=AutomationControlled',
      '--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36'
    ]
  });

  const page = await browser.newPage();
  
  // Ghi đè thuộc tính webdriver để tránh bị phát hiện
  await page.evaluateOnNewDocument(() => {
    Object.defineProperty(navigator, 'webdriver', { get: () => false });
  });

  try {
    console.log(`Đang truy cập nguồn dự phòng: ${url}`);
    
    // Tăng timeout và đợi trang tĩnh
    await page.goto(url, { waitUntil: "networkidle2", timeout: 60000 });
    
    // Chờ thêm một chút để chắc chắn bảng đã render
    await new Promise(r => setTimeout(r, 4000));

    const provincesData = await page.evaluate((targetDate) => {
      // Tìm tất cả các box chứa bảng kết quả
      const boxes = Array.from(document.querySelectorAll(".box-kqxs"));
      // Tìm đúng box có chứa ngày hôm nay (02/04/2026)
      const targetBox = boxes.find(b => b.innerText.includes(targetDate));

      if (!targetBox) return [];

      const table = targetBox.querySelector("table");
      if (!table) return [];

      const results = [];
      const rows = Array.from(table.querySelectorAll("tr"));

      // 1. Lấy tên tỉnh (Hàng đầu tiên chứa link tỉnh)
      const provinceNodes = rows[0].querySelectorAll("th a, td a");
      const provinces = [];
      provinceNodes.forEach(node => {
        const name = node.innerText.trim();
        if (name && name.length > 2) {
          provinces.push({
            province: name,
            full: { G8:[], G7:[], G6:[], G5:[], G4:[], G3:[], G2:[], G1:[], DB:[] }
          });
        }
      });

      // 2. Duyệt từng hàng giải (Bắt đầu từ hàng thứ 2)
      for (let i = 1; i < rows.length; i++) {
        const cells = rows[i].querySelectorAll("th, td");
        if (cells.length < 2) continue;

        let label = cells[0].innerText.trim();
        let key = "";
        if (label === "ĐB") key = "DB";
        else if (!isNaN(label)) key = `G${label}`;
        else continue;

        // Điền số vào từng tỉnh theo cột
        for (let j = 1; j < cells.length; j++) {
          const pIdx = j - 1;
          if (provinces[pIdx]) {
            // Lấy toàn bộ số trong ô, tách ra nếu có nhiều số (G6, G4)
            const text = cells[j].innerText.trim();
            const nums = text.split(/[\s\n\r]+/).filter(v => v !== "" && !isNaN(v));
            provinces[pIdx].full[key] = nums;
          }
        }
      }

      return provinces;
    }, targetDateSlash);

    await browser.close();

    const [year, month, day] = date.split("-").map(Number);
    return {
      date: new Date(year, month - 1, day),
      region: "mien-nam",
      provinces: provincesData.filter(p => p.full.DB.length > 0)
    };

  } catch (error) {
    if (browser) await browser.close();
    console.error("LỖI CRAWL:", error.message);
    return { date: null, region: "mien-nam", provinces: [] };
  }
};