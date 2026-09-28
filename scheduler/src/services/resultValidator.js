/**
 * resultValidator.js
 * Kiểm tra tính đầy đủ của kết quả xổ số XSMN.
 *
 * Quy tắc:
 * - Giữ nguyên số 0 ở đầu (không chuyển "012345" thành "12345")
 * - Kiểm tra số lượng giải theo đúng chuẩn XSMN
 * - Trạng thái: COMPLETE | INCOMPLETE
 */

import { PRIZE_COUNTS, TOTAL_PRIZES } from './crawlerAdapter.js';

// Độ dài tối thiểu của số trong từng giải XSMN (thường 2 chữ số trở lên)
const MIN_NUMBER_LENGTH = 2;

/**
 * Kiểm tra một số có hợp lệ không.
 * Giữ nguyên số 0 ở đầu — validate bằng chuỗi, không parse số.
 *
 * @param {string} value
 * @returns {boolean}
 */
function isValidNumber(value) {
  if (typeof value !== 'string') return false;
  if (value.length < MIN_NUMBER_LENGTH) return false;
  // Chỉ chứa chữ số (0-9)
  return /^\d+$/.test(value);
}

/**
 * Kiểm tra một tỉnh có kết quả đầy đủ không.
 *
 * @param {{ province: string, full: Object }} provinceData
 * @returns {{ isComplete: boolean, missingPrizes: string[], totalPrizes: number }}
 */
export function validateProvince(provinceData) {
  if (!provinceData || !provinceData.full) {
    return { isComplete: false, missingPrizes: Object.keys(PRIZE_COUNTS), totalPrizes: 0 };
  }

  const { full } = provinceData;
  const missingPrizes = [];
  let totalPrizes = 0;

  for (const [prize, expectedCount] of Object.entries(PRIZE_COUNTS)) {
    const values = full[prize] || [];
    // Lọc ra các giá trị hợp lệ (giữ số 0 đầu)
    const validValues = values.filter(isValidNumber);

    if (validValues.length < expectedCount) {
      missingPrizes.push(prize);
    }

    totalPrizes += validValues.length;
  }

  return {
    isComplete: missingPrizes.length === 0,
    missingPrizes,
    totalPrizes,
    expectedTotal: TOTAL_PRIZES,
  };
}

/**
 * Kiểm tra toàn bộ kết quả crawl có đầy đủ không.
 *
 * @param {{ date: string, region: string, provinces: Array }} crawlResult
 * @returns {{ status: 'COMPLETE'|'INCOMPLETE', details: Array, summary: Object }}
 */
export function validateResult(crawlResult) {
  const { provinces = [] } = crawlResult;

  if (provinces.length === 0) {
    return {
      status: 'INCOMPLETE',
      details: [],
      summary: {
        total: 0,
        complete: 0,
        incomplete: 0,
        reason: 'Không có dữ liệu',
      },
    };
  }

  const details = provinces.map((p) => {
    const validation = validateProvince(p);
    return {
      province: p.province,
      ...validation,
    };
  });

  const completeCount = details.filter((d) => d.isComplete).length;
  const incompleteCount = details.filter((d) => !d.isComplete).length;
  const allComplete = incompleteCount === 0 && completeCount > 0;

  return {
    status: allComplete ? 'COMPLETE' : 'INCOMPLETE',
    details,
    summary: {
      total: details.length,
      complete: completeCount,
      incomplete: incompleteCount,
    },
  };
}

/**
 * Merge dữ liệu mới vào dữ liệu hiện có.
 * Không ghi đè giải hợp lệ bằng mảng rỗng.
 * Không đánh dấu COMPLETE nếu dữ liệu mới chưa đầy đủ.
 *
 * @param {Object} existing - Dữ liệu hiện có từ DB (province.full)
 * @param {Object} incoming - Dữ liệu mới từ crawler (province.full)
 * @returns {Object} Dữ liệu đã merge
 */
export function mergePrizeFull(existing, incoming) {
  const merged = { ...existing };

  for (const prize of Object.keys(PRIZE_COUNTS)) {
    const existingValues = existing[prize] || [];
    const incomingValues = (incoming[prize] || []).filter(
      (v) => typeof v === 'string' && /^\d+$/.test(v) && v.length >= MIN_NUMBER_LENGTH
    );

    // Chỉ cập nhật nếu dữ liệu mới có nhiều hơn hoặc bằng dữ liệu cũ
    // Không xóa giải đã có hợp lệ
    if (incomingValues.length >= existingValues.length) {
      merged[prize] = incomingValues;
    } else {
      merged[prize] = existingValues;
    }
  }

  return merged;
}

/**
 * Kiểm tra hai kết quả có giống nhau không (để skip không cần thiết).
 *
 * @param {Array} existingProvinces
 * @param {Array} incomingProvinces
 * @returns {boolean}
 */
export function isDataIdentical(existingProvinces, incomingProvinces) {
  if (existingProvinces.length !== incomingProvinces.length) return false;

  for (const incoming of incomingProvinces) {
    const existing = existingProvinces.find((p) => p.province === incoming.province);
    if (!existing) return false;

    for (const prize of Object.keys(PRIZE_COUNTS)) {
      const existArr = (existing.full?.[prize] || []).join(',');
      const incomArr = (incoming.full?.[prize] || []).join(',');
      if (existArr !== incomArr) return false;
    }
  }

  return true;
}
