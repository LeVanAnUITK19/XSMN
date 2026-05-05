import Result from "../models/results.js";
import { saveResult as saveResultService } from "../services/saveResult.js";
import redis from "../services/redis.js";
import { cacheCounter } from '../config/metrics.js';



const CACHE_KEY = 'results:all';
const CACHE_TTL = 60 * 2; // 5 minutes


// GET all results
export const getResults = async (req, res) => {
  try {
    // 1. Thử lấy từ cache
    const cached = await redis.get(CACHE_KEY);
    if (cached) {
      cacheCounter.inc({ result: 'hit' });
      return res.json(JSON.parse(cached));
    }

    // 2. Cache miss → query MongoDB
    cacheCounter.inc({ result: 'miss' });
    const data = await Result.find().sort({ date: -1 });

    // 3. Lưu vào cache
    await redis.setex(CACHE_KEY, CACHE_TTL, JSON.stringify(data));

    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET by region and/or date
export const getResultByRegion = async (req, res) => {
  try {
    const { region, date } = req.query;

    const query = {};
    if (region) query.region = region;
    if (date) query.date = new Date(date);

    const data = await Result.find(query).sort({ date: -1 });
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET by province name (nested inside provinces array)
export const getResultByProvince = async (req, res) => {
  try {
    const { province, date } = req.query;

    const query = {};
    if (province) query["provinces.province"] = province;
    if (date) query.date = new Date(date);

    const data = await Result.find(query).sort({ date: -1 });
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// CREATE
export const createResult = async (req, res) => {
  try {
    const newData = await Result.create(req.body);
    res.status(201).json(newData);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const saveResult = async (req, res) => {
  try {
    const { date, region, provinces } = req.body;
    const result = await saveResultService({ date, region, provinces });

    // Xóa cache để lần sau fetch lại data mới
    await redis.del('results:all');

    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};


