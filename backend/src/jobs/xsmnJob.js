import cron from "node-cron";
import { crawlXSMN } from "../services/crawlXSMN.js";
import { saveResult } from "../services/saveResult.js";

cron.schedule("*/5 16 * * *", async () => {
  try {
    const date = new Date().toLocaleDateString("sv-SE");// Lấy ngày hiện tại theo format YYYY-MM-DD
    console.log("CRON TRIGGER:", new Date().toString());
    const provinces = await crawlXSMN(date);
    console.log("CRAWL RESULT:", JSON.stringify(provinces, null, 2));

     if (!provinces.provinces?.length) {
  provinces.provinces = [
    {
      province: "Đang cập nhật",
      full: {
        G8: ["Đang cập nhật"],
        G7: ["Đang cập nhật"],
        G6: ["Đang cập nhật"],
        G5: ["Đang cập nhật"],
        G4: ["Đang cập nhật"],
        G3: ["Đang cập nhật"],
        G2: ["Đang cập nhật"],
        G1: ["Đang cập nhật"],
        DB: ["Đang cập nhật"],
      }
    }
  ];
}
    for (const province of provinces.provinces || []) {
      for (let i = 1; i < 9; i++) {
        const key = `G${i}`;

        if (!province.full[key] || province.full[key].length === 0) {
          province.full[key] = ["Đang cập nhật"];
        }
      }

      if (!province.full.DB || province.full.DB.length === 0) {
        province.full.DB = ["Đang cập nhật"];
      }
    }
  
    await saveResult({
      date,
      region: "mien-nam",
      provinces: provinces.provinces || [],
    });

    console.log("Crawl success:", date);
  } catch (err) {
    console.error(err);
  }
});

cron.schedule("* * * * *", async () => {
  try {
    const date = new Date().toLocaleDateString("sv-SE");// Lấy ngày hiện tại theo format YYYY-MM-DD
    console.log("CRON TRIGGER:", new Date().toString());
    const provinces = await crawlXSMN(date);
    console.log("CRAWL RESULT:", JSON.stringify(provinces, null, 2));

    if (!provinces.provinces?.length) {
  provinces.provinces = [
    {
      province: "Đang cập nhật",
      full: {
        G8: ["Đang cập nhật"],
        G7: ["Đang cập nhật"],
        G6: ["Đang cập nhật"],
        G5: ["Đang cập nhật"],
        G4: ["Đang cập nhật"],
        G3: ["Đang cập nhật"],
        G2: ["Đang cập nhật"],
        G1: ["Đang cập nhật"],
        DB: ["Đang cập nhật"],
      }
    }
  ];
}
    for (const province of provinces.provinces || []) {
      for (let i = 1; i < 9; i++) {
        const key = `G${i}`;

        if (!province.full[key] || province.full[key].length === 0) {
          province.full[key] = ["Đang cập nhật"];
        }
      }

      if (!province.full.DB || province.full.DB.length === 0) {
        province.full.DB = ["Đang cập nhật"];
      }
    }

    await saveResult({
      date,
      region: "mien-nam",
      provinces: provinces.provinces || [],
    });

    console.log("Crawl success:", date);
  } catch (err) {
    console.error(err);
  }
});