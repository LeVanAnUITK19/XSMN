import { crawlXSMN } from "../services/crawlXSMN.js";


(async () => {
  const result = await crawlXSMN("2026-04-03");
  console.log("RESULT:", JSON.stringify(result, null, 2));
})();

