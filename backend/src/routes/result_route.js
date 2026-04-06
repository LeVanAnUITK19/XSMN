import express from "express";
import {
  getResults,
  getResultByRegion,
  getResultByProvince,
  createResult
} from "../controllers/result_controller.js";
import { crawlXSMN } from "../services/crawlXSMN.js";

const router = express.Router();

router.get("/", getResults);
router.get("/filter", getResultByRegion);
router.get("/filter-province", getResultByProvince);
router.post("/", createResult);

let isRunning = false;

router.get('/cron/xsmn', async (req, res) => {
  if (isRunning) return res.send('Already running');

  isRunning = true;

  try {
    console.log("CRON START");

    await crawlXSMN("2026-04-03");

    console.log("CRON DONE");

    res.send('ok');
  } catch (err) {
    console.error("CRON ERROR:", err);  // 🔥 xem log Render

    res.status(500).json({
      message: err.message
    });
  } finally {
    isRunning = false;
  }
});

router.get('/health', (req, res) => res.send('ok'));

export default router;