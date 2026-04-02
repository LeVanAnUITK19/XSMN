import mongoose from "mongoose";

const provinceSchema = new mongoose.Schema({
  province: String,

  full: {
    G8: { type: [String], default: [] },
    G7: { type: [String], default: [] },
    G6: { type: [String], default: [] },
    G5: { type: [String], default: [] },
    G4: { type: [String], default: [] },
    G3: { type: [String], default: [] },
    G2: { type: [String], default: [] },
    G1: { type: [String], default: [] },
    DB: { type: [String], default: [] },
  }
});

const resultSchema = new mongoose.Schema({
  date: {
    type: Date,
    required: true,
    index: true
  },

  region: {
    type: String,
    enum: ["mien-nam", "mien-trung", "mien-bac"],
    required: true
  },

  provinces: [provinceSchema],

  createdAt: {
    type: Date,
    default: Date.now
  }
});

// ✔️ đúng index
resultSchema.index({ date: 1, region: 1 }, { unique: true });

const Result = mongoose.model("Result", resultSchema);

export default Result;