import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { buildDigits } from "../src/helps/digit.js";

describe("buildDigits", () => {
  it("slices last 2 and 3 digits for flat prize values", () => {
    const full = {
      G8: ["12"],
      G7: ["123"],
    };
    const { twoDigits, threeDigits } = buildDigits(full);
    assert.deepEqual(twoDigits, ["12", "23"]);
    assert.deepEqual(threeDigits, ["12", "123"]);
  });
});
