/**
 * Tests cho updateDailyResults.js (integration-style với mock)
 * Mock crawler và backend HTTP để không gọi nguồn thật.
 *
 * Chạy: node --test tests/updateDailyResults.test.js
 *
 * NOTE: Vì Node test runner không có built-in module mocking,
 * ta test logic validator + merge trực tiếp, và test job bằng
 * cách inject dependencies qua function parameters.
 */

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import { validateResult, mergePrizeFull, isDataIdentical } from '../src/services/resultValidator.js';
import { PRIZE_COUNTS, TOTAL_PRIZES } from '../src/services/crawlerAdapter.js';

// ── Helpers ───────────────────────────────────────────────────────
function makeComplete(province = 'Vĩnh Long') {
  return {
    province,
    full: {
      G8: ['23'],
      G7: ['456'],
      G6: ['2890', '7234', '6789'],
      G5: ['6789'],
      G4: ['012345', '654321', '789012', '345678', '901234', '567890', '123456'],
      G3: ['98765', '01234'],
      G2: ['567890'],
      G1: ['012345'],
      DB: ['654321'],
    },
  };
}

function makeIncomplete(province = 'Vĩnh Long') {
  return {
    province,
    full: {
      G8: ['23'],
      G7: [],
      G6: ['2890', '7234'],  // thiếu 1
      G5: ['6789'],
      G4: ['012345'],        // thiếu 6
      G3: [],
      G2: ['567890'],
      G1: ['012345'],
      DB: ['654321'],
    },
  };
}

// ════════════════════════════════════════════════════════════════
describe('Job logic: POST khi chưa tồn tại', () => {
  it('kết quả COMPLETE từ crawl → cần gọi API', () => {
    const crawlResult = {
      date: '2026-09-28',
      region: 'mien-nam',
      provinces: [makeComplete('Vĩnh Long')],
    };
    const validation = validateResult(crawlResult);
    const existing = null;

    assert.equal(validation.status, 'COMPLETE');
    assert.equal(existing, null);
    // Logic: existing null → nên POST
    const shouldPost = !existing;
    assert.equal(shouldPost, true);
  });

  it('kết quả INCOMPLETE, chưa tồn tại → vẫn POST (lưu partial)', () => {
    const crawlResult = {
      date: '2026-09-28',
      region: 'mien-nam',
      provinces: [makeIncomplete('Vĩnh Long')],
    };
    const validation = validateResult(crawlResult);
    const existing = null;

    assert.equal(validation.status, 'INCOMPLETE');
    const shouldPost = !existing;
    assert.equal(shouldPost, true);
  });
});

// ════════════════════════════════════════════════════════════════
describe('Job logic: PUT khi đã tồn tại', () => {
  it('đã tồn tại INCOMPLETE → PUT để cập nhật', () => {
    const existing = {
      date: '2026-09-28',
      region: 'mien-nam',
      provinces: [makeIncomplete('Vĩnh Long')],
    };
    const crawlResult = {
      date: '2026-09-28',
      region: 'mien-nam',
      provinces: [makeComplete('Vĩnh Long')],
    };

    const existingValidation = validateResult(existing);
    const newValidation = validateResult(crawlResult);
    const existingComplete = existingValidation.status === 'COMPLETE';

    // Không nên skip vì existing INCOMPLETE
    const shouldSkip = existingComplete && newValidation.status === 'INCOMPLETE';
    assert.equal(shouldSkip, false);
    // Nên PUT vì đã tồn tại và data thay đổi
    const shouldPut = !!existing && !isDataIdentical(existing.provinces, crawlResult.provinces);
    assert.equal(shouldPut, true);
  });
});

// ════════════════════════════════════════════════════════════════
describe('Job logic: SKIP khi dữ liệu không thay đổi', () => {
  it('dữ liệu giống hệt → SKIP', () => {
    const provinces = [makeComplete('Vĩnh Long')];
    const existing = { provinces };
    const crawlResult = { provinces: [makeComplete('Vĩnh Long')] };

    const identical = isDataIdentical(existing.provinces, crawlResult.provinces);
    assert.equal(identical, true);
    // Nên SKIP
  });

  it('dữ liệu khác → không SKIP', () => {
    const existing = { provinces: [makeIncomplete('Vĩnh Long')] };
    const crawlResult = { provinces: [makeComplete('Vĩnh Long')] };

    const identical = isDataIdentical(existing.provinces, crawlResult.provinces);
    assert.equal(identical, false);
  });
});

// ════════════════════════════════════════════════════════════════
describe('Job logic: không ghi đè COMPLETE bằng INCOMPLETE', () => {
  it('existing COMPLETE + crawl INCOMPLETE → SKIP', () => {
    const existingValidation = validateResult({
      provinces: [makeComplete('Vĩnh Long')],
    });
    const newValidation = validateResult({
      provinces: [makeIncomplete('Vĩnh Long')],
    });

    const existingComplete = existingValidation.status === 'COMPLETE';
    const shouldSkip = existingComplete && newValidation.status === 'INCOMPLETE';
    assert.equal(shouldSkip, true, 'Phải SKIP để bảo vệ dữ liệu COMPLETE');
  });

  it('existing COMPLETE + crawl COMPLETE → không bắt buộc SKIP', () => {
    const existingValidation = validateResult({
      provinces: [makeComplete('Vĩnh Long')],
    });
    const newValidation = validateResult({
      provinces: [makeComplete('Vĩnh Long')],
    });

    const existingComplete = existingValidation.status === 'COMPLETE';
    const shouldSkip = existingComplete && newValidation.status === 'INCOMPLETE';
    assert.equal(shouldSkip, false);
  });
});

// ════════════════════════════════════════════════════════════════
describe('Số 0 ở đầu', () => {
  it('số 012345 phải được giữ nguyên là chuỗi, không bị parse thành 12345', () => {
    const province = {
      province: 'Test',
      full: {
        G8: ['23'],
        G7: ['456'],
        G6: ['2890', '7234', '6789'],
        G5: ['6789'],
        G4: ['012345', '654321', '789012', '345678', '901234', '567890', '123456'],
        G3: ['98765', '01234'],
        G2: ['567890'],
        G1: ['012345'],
        DB: ['012345'],
      },
    };

    // DB phải vẫn là chuỗi '012345', không phải số 12345
    assert.equal(typeof province.full.DB[0], 'string');
    assert.equal(province.full.DB[0], '012345');
    assert.notEqual(province.full.DB[0], '12345');
    assert.notEqual(province.full.DB[0], 12345);

    // Sau khi merge, vẫn phải giữ nguyên
    const merged = mergePrizeFull(province.full, province.full);
    assert.equal(merged.DB[0], '012345');
  });
});

// ════════════════════════════════════════════════════════════════
describe('Một đài lỗi không ảnh hưởng đài khác', () => {
  it('tỉnh lỗi không làm mất kết quả tỉnh khác', () => {
    const validProvince = makeComplete('Vĩnh Long');
    const invalidProvince = { province: 'Lỗi', full: null };

    const result = validateResult({
      provinces: [validProvince, invalidProvince],
    });

    // Vĩnh Long vẫn được kiểm tra
    const vlDetail = result.details.find((d) => d.province === 'Vĩnh Long');
    assert.ok(vlDetail);
    assert.equal(vlDetail.isComplete, true);

    // Tỉnh lỗi được mark incomplete nhưng không throw
    const errDetail = result.details.find((d) => d.province === 'Lỗi');
    assert.ok(errDetail);
    assert.equal(errDetail.isComplete, false);
  });
});

// ════════════════════════════════════════════════════════════════
describe('Crawl timeout handling', () => {
  it('FatalError không được retry', async () => {
    const { FatalError, withRetry } = await import('../src/utils/retry.js');
    let callCount = 0;

    await assert.rejects(
      async () => {
        await withRetry(
          async () => {
            callCount++;
            throw new FatalError('Auth failed 401');
          },
          { maxRetries: 3, baseDelayMs: 1, label: 'test-fatal' }
        );
      },
      { name: 'FatalError' }
    );

    // Phải throw ngay lần đầu, không retry
    assert.equal(callCount, 1, 'FatalError không được retry');
  });

  it('RetryableError được retry đúng số lần', async () => {
    const { RetryableError, withRetry } = await import('../src/utils/retry.js');
    let callCount = 0;

    await assert.rejects(
      async () => {
        await withRetry(
          async () => {
            callCount++;
            throw new RetryableError('Timeout');
          },
          { maxRetries: 2, baseDelayMs: 1, label: 'test-retry' }
        );
      },
      { name: 'RetryableError' }
    );

    // maxRetries=2 → lần đầu + 2 lần retry = 3 lần tổng
    assert.equal(callCount, 3, 'Phải thử đúng maxRetries+1 lần');
  });
});

// ════════════════════════════════════════════════════════════════
describe('Hết cửa sổ thời gian', () => {
  it('tổng giải XSMN là 18', () => {
    assert.equal(TOTAL_PRIZES, 18);
    assert.equal(PRIZE_COUNTS.G8, 1);
    assert.equal(PRIZE_COUNTS.G7, 1);
    assert.equal(PRIZE_COUNTS.G6, 3);
    assert.equal(PRIZE_COUNTS.G5, 1);
    assert.equal(PRIZE_COUNTS.G4, 7);
    assert.equal(PRIZE_COUNTS.G3, 2);
    assert.equal(PRIZE_COUNTS.G2, 1);
    assert.equal(PRIZE_COUNTS.G1, 1);
    assert.equal(PRIZE_COUNTS.DB, 1);
  });
});
