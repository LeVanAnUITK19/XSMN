import Result from "../models/results.js";
import { saveResult as saveResultService } from "../services/saveResult.js";
import redis from "../services/redis.js";

// ── Cache keys ────────────────────────────────────────────────────
const CACHE_KEY = 'results:all:p1:l20';
const CACHE_TTL = 60 * 30;            // 30 phút — data xổ số chỉ update 1 lần/ngày

const filterCacheKey = (params) =>
  `results:filter:${JSON.stringify(params)}`;

const FILTER_CACHE_TTL      = 60 * 5;  // 5 phút — không có date cụ thể
const FILTER_DATE_CACHE_TTL = 60 * 60; // 60 phút — có date cụ thể (data cố định)

// ── Helper: parse pagination params ──────────────────────────────
function parsePagination(query) {
  const page  = Math.max(1, parseInt(query.page  || '1',  10));
  const limit = Math.min(50, Math.max(1, parseInt(query.limit || '20', 10)));
  const skip  = (page - 1) * limit;
  return { page, limit, skip };
}

// ── GET /api/results?page=1&limit=20 ─────────────────────────────
// Pagination để tránh dump toàn bộ collection → giảm Heap + Event Loop lag
export const getResults = async (req, res) => {
  try {
    const { page, limit, skip } = parsePagination(req.query);
    const cacheKey = `results:all:p${page}:l${limit}`;

    // 1. Thử cache
    const cached = await redis.get(cacheKey);
    if (cached) {
      return res.json(JSON.parse(cached));
    }

    // 2. Cache miss → query MongoDB với limit
    const [data, total] = await Promise.all([
      Result.find().sort({ date: -1 }).skip(skip).limit(limit).lean(), // .lean() → plain JS object, nhẹ hơn Mongoose document
      Result.countDocuments(),
    ]);

    const payload = {
      data,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasNext: page * limit < total,
      },
    };

    await redis.setex(cacheKey, CACHE_TTL, JSON.stringify(payload));

    // Cache-Control: client/CDN cache 5 phút, stale-while-revalidate thêm 1 phút
    res.set('Cache-Control', 'public, max-age=300, stale-while-revalidate=60');
    res.json(payload);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ── GET /api/results/filter?region=&date=&page=&limit= ────────────
export const getResultByRegion = async (req, res) => {
  try {
    const { region, date, page: pageQ, limit: limitQ } = req.query;
    const { page, limit, skip } = parsePagination({ page: pageQ, limit: limitQ });
    const cacheKey = filterCacheKey({ region, date, page, limit });

    const cached = await redis.get(cacheKey);
    if (cached) {
      return res.json(JSON.parse(cached));
    }

    const query = {};
    if (region) query.region = region;
    if (date)   query.date   = new Date(date);

    const [data, total] = await Promise.all([
      Result.find(query).sort({ date: -1 }).skip(skip).limit(limit).lean(),
      Result.countDocuments(query),
    ]);

    const payload = {
      data,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };

    const ttl = date ? FILTER_DATE_CACHE_TTL : FILTER_CACHE_TTL;
    await redis.setex(cacheKey, ttl, JSON.stringify(payload));

    res.json(payload);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ── GET /api/results/filter-province?province=&date= ─────────────
export const getResultByProvince = async (req, res) => {
  try {
    const { province, date, page: pageQ, limit: limitQ } = req.query;
    const { page, limit, skip } = parsePagination({ page: pageQ, limit: limitQ });
    const cacheKey = filterCacheKey({ province, date, page, limit });

    const cached = await redis.get(cacheKey);
    if (cached) {
      return res.json(JSON.parse(cached));
    }

    const query = {};
    if (province) query["provinces.province"] = province;
    if (date)     query.date = new Date(date);

    const [data, total] = await Promise.all([
      Result.find(query).sort({ date: -1 }).skip(skip).limit(limit).lean(),
      Result.countDocuments(query),
    ]);

    const payload = {
      data,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };

    const ttl = date ? FILTER_DATE_CACHE_TTL : FILTER_CACHE_TTL;
    await redis.setex(cacheKey, ttl, JSON.stringify(payload));

    res.json(payload);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ── POST /api/results ─────────────────────────────────────────────
export const createResult = async (req, res) => {
  try {
    const newData = await Result.create(req.body);
    res.status(201).json(newData);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ── PUT /api/results ──────────────────────────────────────────────
export const saveResult = async (req, res) => {
  try {
    const { date, region, provinces } = req.body;
    const result = await saveResultService({ date, region, provinces });

    // Xóa tất cả cache liên quan khi có data mới
    // Dùng pattern delete để clear tất cả pages
    const keys = await redis.keys('results:*');
    if (keys.length > 0) {
      await redis.del(...keys);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
