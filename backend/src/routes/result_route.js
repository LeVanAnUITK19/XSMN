import express from "express";
import {
  getResults,
  getResultByRegion,
  getResultByProvince,
  createResult,
  saveResult
} from "../controllers/result_controller.js";

const router = express.Router();

router.get("/", getResults);
router.get("/filter", getResultByRegion);
router.get("/filter-province", getResultByProvince);
router.post("/", createResult);
router.put("/", saveResult);

router.get("/health", (req, res) => {
  res.send("OK");
});


export default router;