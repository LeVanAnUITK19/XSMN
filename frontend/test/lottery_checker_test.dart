/// Unit tests cho Lottery Checking Engine — XSMN
///
/// Bao gồm 16 test cases bắt buộc theo yêu cầu:
/// - Logic dò tất cả giải (không dừng sớm)
/// - Giải Phụ Đặc Biệt và Giải Khuyến Khích
/// - Một vé trúng nhiều giải đồng thời
/// - Xử lý số 0 đầu vé
/// - Validation dữ liệu thiếu
/// - Tính thuế TNCN từ 01/07/2026 (ngưỡng 20 triệu)
import 'package:flutter_test/flutter_test.dart';
import 'package:XSMN/core/lottery/lottery_checker.dart';
import 'package:XSMN/core/lottery/lottery_check_result.dart';
import 'package:XSMN/core/lottery/tax_calculator.dart';

// ─────────────────────────────────────────────
// Helper: tạo bộ kết quả quay đầy đủ (18 số)
// Mặc định dùng số KHÔNG trùng với các vé test thông thường
// ─────────────────────────────────────────────

Map<String, List<String>> _fullResults({
  String db = '476833',
  String g1 = '88881',
  String g2 = '88882',
  List<String> g3 = const ['88883', '88884'],
  List<String> g4 = const ['88885', '88886', '88887', '88888', '88889', '88890', '88891'],
  String g5 = '8880',
  List<String> g6 = const ['8881', '8882', '8883'],
  String g7 = '888',
  String g8 = '88',
}) {
  return {
    'DB': [db],
    'G1': [g1],
    'G2': [g2],
    'G3': g3,
    'G4': g4,
    'G5': [g5],
    'G6': g6,
    'G7': [g7],
    'G8': [g8],
  };
}

final _date = DateTime(2026, 9, 26);
const _station = 'Vĩnh Long';

void main() {
  // ════════════════════════════════════════════
  // GROUP 1: Dò các giải chính
  // ════════════════════════════════════════════

  group('Giải chính', () {
    // TEST 1 — Trùng đủ 6 số → Giải Đặc Biệt
    test('TEST 1: Trùng đủ 6 số → Giải Đặc Biệt', () {
      final results = _fullResults(db: '476833');
      final r = LotteryChecker.check(
        ticketNumber: '476833',
        station: _station,
        drawDate: _date,
        results: results,
      );

      expect(r.isWinner, isTrue);
      expect(r.winnings.any((w) => w.prizeCode == 'DB'), isTrue);
      expect(
        r.winnings.firstWhere((w) => w.prizeCode == 'DB').amount,
        equals(2000000000),
      );
    });

    // TEST 2 — Sai số đầu, giống 5 số cuối → Giải Phụ Đặc Biệt
    test('TEST 2: Sai số đầu, giống 5 số cuối → Giải Phụ Đặc Biệt', () {
      // Đặc biệt: 476833 — ticket: 376833
      // ticket[0]='3' != db[0]='4' ✓
      // ticket.substring(1)='76833' == db.substring(1)='76833' ✓
      final results = _fullResults(db: '476833');
      final r = LotteryChecker.check(
        ticketNumber: '376833',
        station: _station,
        drawDate: _date,
        results: results,
      );

      expect(r.isWinner, isTrue);
      expect(r.winnings.any((w) => w.prizeCode == 'DB_PHU'), isTrue);
      // KHÔNG trúng Giải Đặc Biệt
      expect(r.winnings.any((w) => w.prizeCode == 'DB'), isFalse);
      expect(
        r.winnings.firstWhere((w) => w.prizeCode == 'DB_PHU').amount,
        equals(50000000),
      );
    });

    // TEST 3 — Giống số đầu, sai đúng 1 trong 5 số còn lại → Giải Khuyến Khích
    test('TEST 3: Giống số đầu, sai đúng 1 số → Giải Khuyến Khích', () {
      // Đặc biệt: 476833 — ticket: 476838
      // ticket[0]='4' == db[0]='4' ✓
      // sai: vị trí 5 ('8' vs '3') → differences = 1 ✓
      final results = _fullResults(db: '476833');
      final r = LotteryChecker.check(
        ticketNumber: '476838',
        station: _station,
        drawDate: _date,
        results: results,
      );

      expect(r.isWinner, isTrue);
      expect(r.winnings.any((w) => w.prizeCode == 'KK'), isTrue);
      expect(r.winnings.any((w) => w.prizeCode == 'DB'), isFalse);
      expect(r.winnings.any((w) => w.prizeCode == 'DB_PHU'), isFalse);
    });

    // TEST 4 — Sai 2 số so với GĐB → Không trúng KK
    test('TEST 4: Sai 2 số so với GĐB → Không trúng KK', () {
      // Đặc biệt: 476833 — ticket: 476813 (vị trí 4 sai '1' vs '3', vị trí 5 sai '3' vs '3'...)
      // db6 = '476833', ticket = '476813'
      // pos0: '4'=='4' ✓
      // pos1: '7'=='7' ✓
      // pos2: '6'=='6' ✓
      // pos3: '8'=='8' ✓
      // pos4: '1'!='3' ✗ differences=1
      // pos5: '3'=='3' ✓ → differences=1 → ĐÂY LÀ KK!
      // Vé đúng để test: 476133 (sai vị trí 3 và 4)
      // db6='476833', ticket='476133'
      // pos1:'7'=='7' ✓  pos2:'6'=='6' ✓  pos3:'1'!='8' ✗  pos4:'3'!='3' ✓  pos5:'3'=='3' ✓
      // Wait: pos3: ticket[3]='1', db6[3]='8' → sai 1
      //        pos4: ticket[4]='3', db6[4]='3' → khớp
      // Thực ra: 476133 vs 476833 → sai chỉ vị trí 3 ('1' vs '8') → differences=1 → KK
      // Dùng vé sai 2 vị trí: 475733
      // db6='476833' ticket='475733'
      // pos1:'7'=='7' ✓ pos2:'5'!='6' ✗ pos3:'7'!='8' ✗ → differences=2 → KHÔNG KK ✓
      final results = _fullResults(db: '476833');
      final r = LotteryChecker.check(
        ticketNumber: '475733',
        station: _station,
        drawDate: _date,
        results: results,
      );

      expect(r.winnings.any((w) => w.prizeCode == 'KK'), isFalse);
      expect(r.winnings.any((w) => w.prizeCode == 'DB'), isFalse);
      expect(r.winnings.any((w) => w.prizeCode == 'DB_PHU'), isFalse);
    });

    // TEST 5 — Trùng 5 số cuối G1 → Giải Nhất
    test('TEST 5: Trùng 5 số cuối G1 → Giải Nhất', () {
      // G1 = '23456' → 5 số cuối vé '123456' == '23456' ✓
      final results = _fullResults(g1: '23456');
      final r = LotteryChecker.check(
        ticketNumber: '123456',
        station: _station,
        drawDate: _date,
        results: results,
      );

      expect(r.isWinner, isTrue);
      expect(r.winnings.any((w) => w.prizeCode == 'G1'), isTrue);
      expect(
        r.winnings.firstWhere((w) => w.prizeCode == 'G1').amount,
        equals(30000000),
      );
    });

    // TEST 6 — Trùng một trong 2 kết quả G3 → Giải Ba
    test('TEST 6: Trùng một trong 2 kết quả G3 → Giải Ba', () {
      // G3 = ['45678', '99999'] — vé '145678' trùng kết quả đầu
      final results = _fullResults(g3: ['45678', '99999']);
      final r = LotteryChecker.check(
        ticketNumber: '145678',
        station: _station,
        drawDate: _date,
        results: results,
      );

      expect(r.isWinner, isTrue);
      expect(r.winnings.any((w) => w.prizeCode == 'G3'), isTrue);
      expect(
        r.winnings.firstWhere((w) => w.prizeCode == 'G3').amount,
        equals(10000000),
      );
    });

    // TEST 7 — Trùng một trong 7 kết quả G4 → Giải Tư
    test('TEST 7: Trùng một trong 7 kết quả G4 → Giải Tư', () {
      // G4[5] = '67890' — vé '167890' trùng
      final results = _fullResults(
        g4: ['11111', '22222', '33333', '44444', '55555', '67890', '77777'],
      );
      final r = LotteryChecker.check(
        ticketNumber: '167890',
        station: _station,
        drawDate: _date,
        results: results,
      );

      expect(r.isWinner, isTrue);
      expect(r.winnings.any((w) => w.prizeCode == 'G4'), isTrue);
      expect(
        r.winnings.firstWhere((w) => w.prizeCode == 'G4').amount,
        equals(3000000),
      );
    });

    // TEST 8 — Trùng một trong 3 kết quả G6 → Giải Sáu
    test('TEST 8: Trùng một trong 3 kết quả G6 → Giải Sáu', () {
      // G6 = ['2345', '9999', '8888'] — vé '112345' trùng kết quả đầu (4 số cuối)
      final results = _fullResults(g6: ['2345', '9999', '8888']);
      final r = LotteryChecker.check(
        ticketNumber: '112345',
        station: _station,
        drawDate: _date,
        results: results,
      );

      expect(r.isWinner, isTrue);
      expect(r.winnings.any((w) => w.prizeCode == 'G6'), isTrue);
      expect(
        r.winnings.firstWhere((w) => w.prizeCode == 'G6').amount,
        equals(400000),
      );
    });
  });

  // ════════════════════════════════════════════
  // GROUP 2: Một vé trúng nhiều giải
  // ════════════════════════════════════════════

  group('Một vé trúng nhiều giải', () {
    // TEST 9 — Vé đồng thời trúng G1 + G6 + G8
    test('TEST 9: Vé trúng G1 + G6 + G8 → 3 giải, tiền cộng đủ', () {
      // Vé: '153456'
      // G1 = '53456'  → 5 số cuối '53456' == '53456' ✓  (30.000.000)
      // G6[0] = '3456' → 4 số cuối '3456' == '3456' ✓   (400.000)
      // G8 = '56'     → 2 số cuối '56' == '56' ✓         (100.000)
      // Tổng: 30.500.000
      // Dùng isolated results — đảm bảo chỉ 3 giải trúng
      final results = {
        'DB': ['999999'],
        'G1': ['53456'],
        'G2': ['88882'],
        'G3': ['88883', '88884'],
        'G4': ['88885', '88886', '88887', '88888', '88889', '88890', '88891'],
        'G5': ['8880'],
        'G6': ['3456', '0000', '1111'],
        'G7': ['888'],
        'G8': ['56'],
      };
      final r = LotteryChecker.check(
        ticketNumber: '153456',
        station: _station,
        drawDate: _date,
        results: results,
      );

      expect(r.isWinner, isTrue);
      expect(r.winnings.length, equals(3));
      expect(r.winnings.any((w) => w.prizeCode == 'G1'), isTrue);
      expect(r.winnings.any((w) => w.prizeCode == 'G6'), isTrue);
      expect(r.winnings.any((w) => w.prizeCode == 'G8'), isTrue);
      expect(r.grossPrize, equals(30000000 + 400000 + 100000)); // 30.500.000
    });
  });

  // ════════════════════════════════════════════
  // GROUP 3: Edge cases
  // ════════════════════════════════════════════

  group('Edge cases', () {
    // TEST 10 — Vé bắt đầu bằng 0 → không mất số 0
    test('TEST 10: Vé 012345 → giữ nguyên số 0 đầu', () {
      // G8 = '45' → 2 số cuối '45' == '45' ✓
      final results = _fullResults(g8: '45');
      final r = LotteryChecker.check(
        ticketNumber: '012345',
        station: _station,
        drawDate: _date,
        results: results,
      );

      // Phải dò đúng với 6 ký tự '012345'
      expect(r.ticketNumber, equals('012345'));
      // G8 '45' khớp 2 số cuối '45' của vé '012345' ✓
      expect(r.winnings.any((w) => w.prizeCode == 'G8'), isTrue);
    });

    // TEST 11 — API thiếu kết quả G4 → dataStatus = incomplete, không báo NOT_WIN
    test('TEST 11: Thiếu G4 → dataStatus = incomplete, không kết luận không trúng', () {
      final incompleteResults = {
        'DB': ['476833'],
        'G1': ['23456'],
        'G2': ['34567'],
        'G3': ['45678', '56789'],
        // G4 bị thiếu (chỉ có 3 trong khi cần 7)
        'G4': ['11111', '22222', '33333'],
        'G5': ['1234'],
        'G6': ['2345', '3456', '4567'],
        'G7': ['123'],
        'G8': ['12'],
      };

      final r = LotteryChecker.check(
        ticketNumber: '123456',
        station: _station,
        drawDate: _date,
        results: incompleteResults,
      );

      expect(r.dataStatus, equals(DataStatus.incomplete));
      // QUAN TRỌNG: isWinner phải là false VÀ winnings trống
      // nhưng lý do là thiếu dữ liệu, không phải không trúng
      expect(r.winnings, isEmpty);
    });
  });

  // ════════════════════════════════════════════
  // GROUP 4: Tính thuế TNCN (từ 01/07/2026)
  // ════════════════════════════════════════════

  group('Thuế TNCN — ngưỡng 20 triệu (từ 01/07/2026)', () {
    // TEST 12 — Tổng thưởng = 20.000.000 → tax = 0
    test('TEST 12: Tổng = 20.000.000 → thuế = 0', () {
      final tax = TaxCalculator.calculate(20000000);
      expect(tax.taxAmount, equals(0));
      expect(tax.netPrize, equals(20000000));
      expect(tax.taxableAmount, equals(0));
    });

    // TEST 13 — Tổng thưởng = 20.100.000 → tax = 10.000
    test('TEST 13: Tổng = 20.100.000 → thuế = 10.000', () {
      final tax = TaxCalculator.calculate(20100000);
      expect(tax.taxableAmount, equals(100000));
      expect(tax.taxAmount, equals(10000));
      expect(tax.netPrize, equals(20090000));
    });

    // TEST 14 — G1 = 30.000.000 → tax = 1.000.000, net = 29.000.000
    test('TEST 14: G1 = 30.000.000 → thuế = 1.000.000, thực nhận = 29.000.000', () {
      // Dùng isolated results: chỉ G1 trúng, không giải nào khác trùng vé
      final results = {
        'DB': ['999999'],
        'G1': ['75432'],  // 5 số cuối vé '175432'
        'G2': ['88882'],
        'G3': ['88883', '88884'],
        'G4': ['88885', '88886', '88887', '88888', '88889', '88890', '88891'],
        'G5': ['8880'],
        'G6': ['8881', '8882', '8883'],
        'G7': ['888'],
        'G8': ['89'], // không trùng '32'
      };
      final r = LotteryChecker.check(
        ticketNumber: '175432',
        station: _station,
        drawDate: _date,
        results: results,
      );

      expect(r.grossPrize, equals(30000000));
      expect(r.taxAmount, equals(1000000));
      expect(r.netPrize, equals(29000000));
    });

    // TEST 15 — GĐB = 2.000.000.000 → tax = 198.000.000, net = 1.802.000.000
    test('TEST 15: GĐB = 2 tỷ → thuế = 198 triệu, thực nhận = 1.802 tỷ', () {
      final results = _fullResults(db: '476833');
      final r = LotteryChecker.check(
        ticketNumber: '476833',
        station: _station,
        drawDate: _date,
        results: results,
      );

      expect(r.grossPrize, equals(2000000000));
      expect(r.taxableAmount, equals(1980000000));
      expect(r.taxAmount, equals(198000000));
      expect(r.netPrize, equals(1802000000));
    });

    // TEST 16 — Vé trúng nhiều giải, tổng 30.500.000 → tax tính trên TỔNG, không tính từng giải
    test('TEST 16: Nhiều giải tổng 30.500.000 → thuế = 1.050.000 (tính trên tổng)', () {
      // G1 = 30.000.000, G6 = 400.000, G8 = 100.000 → tổng = 30.500.000
      // taxable = 30.500.000 - 20.000.000 = 10.500.000
      // tax = 10.500.000 × 10% = 1.050.000
      // net = 30.500.000 - 1.050.000 = 29.450.000
      // Isolated results — vé '153456' chỉ trúng G1 + G6 + G8
      final results = {
        'DB': ['999999'],
        'G1': ['53456'],
        'G2': ['88882'],
        'G3': ['88883', '88884'],
        'G4': ['88885', '88886', '88887', '88888', '88889', '88890', '88891'],
        'G5': ['8880'],
        'G6': ['3456', '0000', '1111'],
        'G7': ['888'],
        'G8': ['56'],
      };
      final r = LotteryChecker.check(
        ticketNumber: '153456',
        station: _station,
        drawDate: _date,
        results: results,
      );

      expect(r.grossPrize, equals(30500000));
      expect(r.taxableAmount, equals(10500000));
      expect(r.taxAmount, equals(1050000));
      expect(r.netPrize, equals(29450000));
    });
  });

  // ════════════════════════════════════════════
  // GROUP 5: Không trúng (kiểm thêm logic nền)
  // ════════════════════════════════════════════

  group('Không trúng', () {
    test('Vé không khớp bất kỳ giải nào → isWinner = false', () {
      // Vé '999999' không khớp bất kỳ số nào trong bộ kết quả mặc định
      final results = _fullResults();
      final r = LotteryChecker.check(
        ticketNumber: '999999',
        station: _station,
        drawDate: _date,
        results: results,
      );

      expect(r.isWinner, isFalse);
      expect(r.winnings, isEmpty);
      expect(r.grossPrize, equals(0));
      expect(r.taxAmount, equals(0));
      expect(r.netPrize, equals(0));
      expect(r.dataStatus, equals(DataStatus.complete));
    });

    test('Vé trùng 5 số cuối GĐB nhưng cũng trùng số đầu → Giải Đặc Biệt, không phải Phụ ĐB', () {
      // db = '476833', ticket = '476833' → trùng đủ 6 số → chỉ là GĐB
      final results = _fullResults(db: '476833');
      final r = LotteryChecker.check(
        ticketNumber: '476833',
        station: _station,
        drawDate: _date,
        results: results,
      );

      expect(r.winnings.any((w) => w.prizeCode == 'DB'), isTrue);
      // Giải Phụ ĐB yêu cầu số đầu KHÁC — trường hợp này không trúng Phụ ĐB
      expect(r.winnings.any((w) => w.prizeCode == 'DB_PHU'), isFalse);
    });

    test('Giải Khuyến Khích: sai số đầu → không trúng KK', () {
      // db = '476833', ticket = '376838'
      // ticket[0]='3' != db[0]='4' → không thỏa điều kiện KK
      final results = _fullResults(db: '476833');
      final r = LotteryChecker.check(
        ticketNumber: '376838',
        station: _station,
        drawDate: _date,
        results: results,
      );

      expect(r.winnings.any((w) => w.prizeCode == 'KK'), isFalse);
    });
  });

  // ════════════════════════════════════════════
  // GROUP 6: TaxCalculator trực tiếp
  // ════════════════════════════════════════════

  group('TaxCalculator', () {
    test('Dưới ngưỡng → taxAmount = 0', () {
      expect(TaxCalculator.calculate(0).taxAmount, equals(0));
      expect(TaxCalculator.calculate(10000000).taxAmount, equals(0));
      expect(TaxCalculator.calculate(19999999).taxAmount, equals(0));
    });

    test('Đúng ngưỡng 20 triệu → taxAmount = 0', () {
      final tax = TaxCalculator.calculate(20000000);
      expect(tax.taxAmount, equals(0));
      expect(tax.taxableAmount, equals(0));
    });

    test('Vượt ngưỡng → taxAmount = (gross - 20tr) × 10%', () {
      final tax = TaxCalculator.calculate(25000000);
      expect(tax.taxableAmount, equals(5000000));
      expect(tax.taxAmount, equals(500000));
      expect(tax.netPrize, equals(24500000));
    });

    test('Giải Phụ ĐB: 50 triệu → thuế = 3 triệu, thực nhận = 47 triệu', () {
      final tax = TaxCalculator.calculate(50000000);
      expect(tax.taxableAmount, equals(30000000));
      expect(tax.taxAmount, equals(3000000));
      expect(tax.netPrize, equals(47000000));
    });
  });

  // ════════════════════════════════════════════
  // GROUP 7: ruleVersion & ruleLastVerifiedAt
  // ════════════════════════════════════════════

  group('Metadata phiên bản', () {
    test('LotteryCheckResult chứa ruleVersion đúng', () {
      final results = _fullResults();
      final r = LotteryChecker.check(
        ticketNumber: '999999',
        station: _station,
        drawDate: _date,
        results: results,
      );
      expect(r.ruleVersion, equals('XSMN-2026.09'));
      expect(r.ruleLastVerifiedAt, equals('2026-09-26'));
    });
  });
}
