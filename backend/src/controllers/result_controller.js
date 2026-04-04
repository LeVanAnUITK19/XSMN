import Result from "../models/results.js";

// GET all results
export const getResults = async (req, res) => {
    try {
        const data = await Result.find().sort({ date: -1 });
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

