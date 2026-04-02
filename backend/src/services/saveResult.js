import Result from "../models/results.js";

export const saveResult = async ({ date, region, provinces }) => {
  return await Result.updateOne(
    { date, region },
    {
      $set: {
        date,
        region,
        provinces
      }
    },
    { upsert: true }
  );
};