import { crawlXSMN1 } from "../services/crawlXSMN1.js";

(async () => {
  console.log("--- BẮT ĐẦU CRAWL THỰC TẾ ---");
  const result = await crawlXSMN1("2026-04-02");
  
  if (result.provinces.length === 0) {
    console.log("❌ Vẫn rỗng. Kiểm tra lại: 1. Web có đang chặn IP không? 2. Ngày hôm nay đã quay số xong chưa?");
  } else {
    console.log("✅ THÀNH CÔNG! Đã lấy được dữ liệu.");
    console.log(JSON.stringify(result, null, 2));
  }
})();