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
    await crawlXSMN();
    res.send('ok');
  } finally {
    isRunning = false;
  }
});

router.get('/health', (req, res) => res.send('ok'));

export default router;