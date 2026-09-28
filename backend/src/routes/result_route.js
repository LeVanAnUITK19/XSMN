import express from "express";
import {
  getResults,
  getResultByRegion,
  getResultByProvince,
  createResult,
  saveResult
} from "../controllers/result_controller.js";
import { schedulerAuthMiddleware } from "../middleware/schedulerAuth.js";

const router = express.Router();

// ── Public read endpoints ─────────────────────────────────────────
router.get("/", getResults);
router.get("/filter", getResultByRegion);
router.get("/filter-province", getResultByProvince);
router.get("/health", (req, res) => res.send("OK"));

// ── Protected write endpoints (scheduler/internal only) ──────────
// schedulerAuthMiddleware kiểm tra Authorization: Bearer <SCHEDULER_API_TOKEN>
// Nếu SCHEDULER_API_TOKEN không set → backward compat (cho phép, log cảnh báo)
router.post("/", schedulerAuthMiddleware, createResult);
router.put("/", schedulerAuthMiddleware, saveResult);

export default router;