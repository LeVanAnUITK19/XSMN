import express from "express";
import {
  getResults,
  getResultByRegion,
  getResultByProvince,
  createResult
} from "../controllers/result_controller.js";

const router = express.Router();

router.get("/", getResults);
router.get("/filter", getResultByRegion);
router.get("/filter-province", getResultByProvince);
router.post("/", createResult);

export default router;