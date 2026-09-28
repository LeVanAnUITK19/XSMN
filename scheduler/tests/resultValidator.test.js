/**
 * Tests cho resultValidator.js
 * Chạy: node --test tests/resultValidator.test.js
 */

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

// Inline test data để không phụ thuộc import nội bộ phức tạp
// Ta import trực tiếp từ src/
import {
  validateProvince,
  validateResult,
  mergePrizeFull,
  isDataIdentical,
} from '../src/services/resultValidator.js';

// ── Helper tạo province hoàn chỉnh ───────────────────────────────
function makeCompleteProvince(name = 'Vĩnh Long') {
  return {
    province: name,
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

function makeIncompleteProvince(name = 'Vĩnh Long') {
  return {
    province: name,
    full: {
      G8: ['23'],
      G7: [],      // thiếu
      G6: ['2890'],
      G5: ['6789'],
      G4: ['012345'],
      G3: [],      // thiếu
      G2: ['567890'],
      G1: ['012345'],
      DB: ['654321'],
    },
  };
}

// ════════════════════════════════════════════════════════════════
describe('validateProvince', () => {
  it('trả về isComplete=true khi đủ tất cả giải', () => {
    const p = makeCompleteProvince();
    const result = validateProvince(p);
    assert.equal(result.isComplete, true);
    assert.equal(result.missingPrizes.length, 0);
    assert.equal(result.totalPrizes, 18);
  });

  it('trả về isComplete=false khi thiếu giải', () => {
    const p = makeIncompleteProvince();
    const result = validateProvince(p);
    assert.equal(result.isComplete, false);
    assert.ok(result.missingPrizes.includes('G7'));
    assert.ok(result.missingPrizes.includes('G3'));
  });

  it('trả về false khi province là null', () => {
    const result = validateProvince(null);
    assert.equal(result.isComplete, false);
  });

  it('giữ nguyên số 0 ở đầu — không convert sang number', () => {
    const p = makeCompleteProvince();
    p.full.DB = ['012345'];
    const result = validateProvince(p);
    assert.equal(result.isComplete, true);
    // Số 0 ở đầu phải được giữ nguyên
    assert.equal(p.full.DB[0], '012345');
    assert.notEqual(p.full.DB[0], '12345');
  });

  it('không chấp nhận số không hợp lệ (1 ký tự)', () => {
    const p = makeCompleteProvince();
    p.full.G8 = ['1']; // quá ngắn
    const result = validateProvince(p);
    assert.equal(result.isComplete, false);
    assert.ok(result.missingPrizes.includes('G8'));
  });

  it('không chấp nhận chuỗi rỗng', () => {
    const p = makeCompleteProvince();
    p.full.DB = [''];
    const result = validateProvince(p);
    assert.equal(result.isComplete, false);
  });
});

// ════════════════════════════════════════════════════════════════
describe('validateResult', () => {
  it('trả về COMPLETE khi tất cả tỉnh đầy đủ', () => {
    const result = validateResult({
      date: '2026-09-28',
      region: 'mien-nam',
      provinces: [makeCompleteProvince('Vĩnh Long'), makeCompleteProvince('An Giang')],
    });
    assert.equal(result.status, 'COMPLETE');
    assert.equal(result.summary.complete, 2);
    assert.equal(result.summary.incomplete, 0);
  });

  it('trả về INCOMPLETE khi có một tỉnh chưa đủ', () => {
    const result = validateResult({
      date: '2026-09-28',
      region: 'mien-nam',
      provinces: [makeCompleteProvince('Vĩnh Long'), makeIncompleteProvince('An Giang')],
    });
    assert.equal(result.status, 'INCOMPLETE');
    assert.equal(result.summary.incomplete, 1);
  });

  it('trả về INCOMPLETE khi không có tỉnh nào', () => {
    const result = validateResult({
      date: '2026-09-28',
      region: 'mien-nam',
      provinces: [],
    });
    assert.equal(result.status, 'INCOMPLETE');
    assert.equal(result.summary.reason, 'Không có dữ liệu');
  });
});

// ════════════════════════════════════════════════════════════════
describe('mergePrizeFull', () => {
  it('giữ nguyên giải hợp lệ khi incoming thiếu', () => {
    const existing = {
      G8: ['23'], G7: ['456'],
      G6: ['2890', '7234', '6789'],
      G5: ['6789'], G4: ['012345', '654321', '789012', '345678', '901234', '567890', '123456'],
      G3: ['98765', '01234'], G2: ['567890'], G1: ['012345'], DB: ['654321'],
    };
    const incoming = {
      G8: ['23'], G7: [],   // G7 rỗng ở incoming
      G6: ['2890', '7234', '6789'],
      G5: ['6789'], G4: ['012345', '654321', '789012', '345678', '901234', '567890', '123456'],
      G3: ['98765', '01234'], G2: ['567890'], G1: ['012345'], DB: ['654321'],
    };

    const merged = mergePrizeFull(existing, incoming);
    // G7 phải giữ lại từ existing vì incoming rỗng
    assert.deepEqual(merged.G7, ['456']);
  });

  it('cập nhật khi incoming có nhiều hơn', () => {
    const existing = { G8: ['23'], G7: ['456'], G6: [], G5: [], G4: [], G3: [], G2: [], G1: [], DB: [] };
    const incoming = { G8: ['99'], G7: ['456'], G6: ['111', '222', '333'], G5: ['444'], G4: ['1','2','3','4','5','6','7'], G3: ['55','66'], G2: ['77'], G1: ['88'], DB: ['00'] };

    const merged = mergePrizeFull(existing, incoming);
    assert.equal(merged.G8[0], '99');
    assert.equal(merged.G6.length, 3);
  });
});

// ════════════════════════════════════════════════════════════════
describe('isDataIdentical', () => {
  it('trả về true khi data giống nhau', () => {
    const provinces = [makeCompleteProvince('Vĩnh Long')];
    assert.equal(isDataIdentical(provinces, provinces), true);
  });

  it('trả về false khi số lượng tỉnh khác nhau', () => {
    const p1 = [makeCompleteProvince('Vĩnh Long')];
    const p2 = [makeCompleteProvince('Vĩnh Long'), makeCompleteProvince('An Giang')];
    assert.equal(isDataIdentical(p1, p2), false);
  });

  it('trả về false khi giá trị giải khác nhau', () => {
    const existing = [makeCompleteProvince('Vĩnh Long')];
    const incoming = [makeCompleteProvince('Vĩnh Long')];
    incoming[0].full.DB = ['999999'];
    assert.equal(isDataIdentical(existing, incoming), false);
  });

  it('trả về false khi tên tỉnh khác', () => {
    const p1 = [makeCompleteProvince('Vĩnh Long')];
    const p2 = [makeCompleteProvince('An Giang')];
    assert.equal(isDataIdentical(p1, p2), false);
  });
});
