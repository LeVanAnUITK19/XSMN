/// Engine dò vé số XSMN — tách hoàn toàn khỏi UI
///
/// NGUYÊN TẮC QUAN TRỌNG:
/// 1. Kiểm tra TOÀN BỘ các giải — không dừng khi tìm thấy giải đầu tiên
/// 2. Lưu tất cả giải trúng vào danh sách
/// 3. Cộng tổng tiền thưởng TRƯỚC khi tính thuế
/// 4. Xử lý đúng Giải Phụ ĐB và Giải Khuyến Khích
/// 5. Số 0 đầu vé phải được giữ nguyên (lưu dạng String)
library;

import 'lottery_check_result.dart';
import 'prize_rule.dart';
import 'tax_calculator.dart';

class LotteryChecker {
  LotteryChecker._();

  /// Dò vé chính
  ///
  /// [ticketNumber] — 6 chữ số, lưu dạng String (giữ số 0 đầu)
  /// [station]      — tên đài/tỉnh
  /// [drawDate]     — ngày mở thưởng
  /// [results]      — Map kết quả quay từ API:
  ///                  key = 'DB','G1'...'G8'
  ///                  value = List(String) các số quay được
  static LotteryCheckResult check({
    required String ticketNumber,
    required String station,
    required DateTime drawDate,
    required Map<String, List<String>> results,
  }) {
    // ── 1. Validate dữ liệu kết quả ─────────────────────────
    final dataStatus = _validateResults(results);
    if (dataStatus != DataStatus.complete) {
      return LotteryCheckResult(
        ticketNumber: ticketNumber,
        station: station,
        drawDate: drawDate,
        isWinner: false,
        winnings: const [],
        grossPrize: 0,
        taxableAmount: 0,
        taxAmount: 0,
        netPrize: 0,
        dataStatus: dataStatus,
      );
    }

    // ── 2. Validate số vé ────────────────────────────────────
    final ticket = ticketNumber.trim();
    if (ticket.length != 6 || !RegExp(r'^\d{6}$').hasMatch(ticket)) {
      return LotteryCheckResult(
        ticketNumber: ticketNumber,
        station: station,
        drawDate: drawDate,
        isWinner: false,
        winnings: const [],
        grossPrize: 0,
        taxableAmount: 0,
        taxAmount: 0,
        netPrize: 0,
        dataStatus: DataStatus.complete,
      );
    }

    // ── 3. Dò tất cả giải — KHÔNG dừng sớm ─────────────────
    final winnings = <WinningPrize>[];

    _checkSpecial(ticket, results, winnings);
    _checkSpecialSecondary(ticket, results, winnings);
    _checkEncouragement(ticket, results, winnings);
    _checkFirst(ticket, results, winnings);
    _checkSecond(ticket, results, winnings);
    _checkThird(ticket, results, winnings);
    _checkFourth(ticket, results, winnings);
    _checkFifth(ticket, results, winnings);
    _checkSixth(ticket, results, winnings);
    _checkSeventh(ticket, results, winnings);
    _checkEighth(ticket, results, winnings);

    // ── 4. Cộng tổng tiền thưởng ────────────────────────────
    final grossPrize = winnings.fold(0, (sum, w) => sum + w.amount);

    // ── 5. Tính thuế trên TỔNG — không tính từng giải ────────
    final tax = TaxCalculator.calculate(grossPrize);

    return LotteryCheckResult(
      ticketNumber: ticket,
      station: station,
      drawDate: drawDate,
      isWinner: winnings.isNotEmpty,
      winnings: winnings,
      grossPrize: tax.grossPrize,
      taxableAmount: tax.taxableAmount,
      taxAmount: tax.taxAmount,
      netPrize: tax.netPrize,
      dataStatus: DataStatus.complete,
    );
  }

  // ── Validate đủ kết quả ──────────────────────────────────────

  static DataStatus _validateResults(Map<String, List<String>> results) {
    for (final entry in XsmnPrizeRules.requiredResultCounts.entries) {
      final key = entry.key;
      final required = entry.value;
      final actual = results[key]?.where((s) => s.trim().isNotEmpty).length ?? 0;
      if (actual < required) {
        return DataStatus.incomplete;
      }
    }
    return DataStatus.complete;
  }

  // ── Giải Đặc Biệt: khớp đủ 6 số ────────────────────────────

  static void _checkSpecial(
    String ticket,
    Map<String, List<String>> results,
    List<WinningPrize> winnings,
  ) {
    for (final raw in results['DB'] ?? <String>[]) {
      final n = _clean(raw);
      if (n.length < 6) continue;
      final db6 = n.substring(n.length - 6);
      if (db6 == ticket) {
        winnings.add(WinningPrize(
          prizeCode: 'DB',
          prizeName: XsmnPrizeRules.specialPrize.name,
          amount: XsmnPrizeRules.specialPrize.amount,
          matchedNumber: n,
        ));
      }
    }
  }

  // ── Giải Phụ Đặc Biệt: 5 số cuối giống, số đầu khác ────────

  static void _checkSpecialSecondary(
    String ticket,
    Map<String, List<String>> results,
    List<WinningPrize> winnings,
  ) {
    for (final raw in results['DB'] ?? <String>[]) {
      final n = _clean(raw);
      if (n.length < 6) continue;
      final db6 = n.substring(n.length - 6);

      // Phải khác số đầu VÀ giống 5 số cuối
      // (ticket[0] != db6[0]) && (ticket.substring(1) == db6.substring(1))
      if (ticket[0] != db6[0] && ticket.substring(1) == db6.substring(1)) {
        winnings.add(WinningPrize(
          prizeCode: 'DB_PHU',
          prizeName: XsmnPrizeRules.specialSecondaryPrize.name,
          amount: XsmnPrizeRules.specialSecondaryPrize.amount,
          matchedNumber: n,
          note: 'Trùng 5 số cuối Giải Đặc Biệt, khác số đầu',
        ));
      }
    }
  }

  // ── Giải Khuyến Khích: số đầu giống, sai đúng 1 trong 5 số còn lại ──

  static void _checkEncouragement(
    String ticket,
    Map<String, List<String>> results,
    List<WinningPrize> winnings,
  ) {
    for (final raw in results['DB'] ?? <String>[]) {
      final n = _clean(raw);
      if (n.length < 6) continue;
      final db6 = n.substring(n.length - 6);

      if (!_isEncouragementPrize(ticket, db6)) continue;

      winnings.add(WinningPrize(
        prizeCode: 'KK',
        prizeName: XsmnPrizeRules.encouragementPrize.name,
        amount: XsmnPrizeRules.encouragementPrize.amount,
        matchedNumber: n,
        note: 'Giống số đầu Giải Đặc Biệt, sai đúng 1 trong 5 số còn lại',
      ));
    }
  }

  /// Logic Giải Khuyến Khích:
  /// - ticket[0] == special[0]  → cùng số đầu
  /// - đếm sai ở vị trí 1..5 == đúng 1
  static bool _isEncouragementPrize(String ticket, String special) {
    if (ticket.length != 6 || special.length != 6) return false;
    if (ticket[0] != special[0]) return false; // số đầu phải giống

    int differences = 0;
    for (int i = 1; i < 6; i++) {
      if (ticket[i] != special[i]) differences++;
    }
    return differences == 1;
  }

  // ── Giải Nhất: 5 số cuối ────────────────────────────────────

  static void _checkFirst(
    String ticket,
    Map<String, List<String>> results,
    List<WinningPrize> winnings,
  ) {
    _checkTailMatch(
      ticket: ticket,
      numbers: results['G1'] ?? [],
      digits: 5,
      prizeCode: 'G1',
      prizeName: XsmnPrizeRules.firstPrize.name,
      amount: XsmnPrizeRules.firstPrize.amount,
      winnings: winnings,
    );
  }

  // ── Giải Nhì: 5 số cuối ─────────────────────────────────────

  static void _checkSecond(
    String ticket,
    Map<String, List<String>> results,
    List<WinningPrize> winnings,
  ) {
    _checkTailMatch(
      ticket: ticket,
      numbers: results['G2'] ?? [],
      digits: 5,
      prizeCode: 'G2',
      prizeName: XsmnPrizeRules.secondPrize.name,
      amount: XsmnPrizeRules.secondPrize.amount,
      winnings: winnings,
    );
  }

  // ── Giải Ba: 5 số cuối, 2 kết quả ───────────────────────────

  static void _checkThird(
    String ticket,
    Map<String, List<String>> results,
    List<WinningPrize> winnings,
  ) {
    _checkTailMatch(
      ticket: ticket,
      numbers: results['G3'] ?? [],
      digits: 5,
      prizeCode: 'G3',
      prizeName: XsmnPrizeRules.thirdPrize.name,
      amount: XsmnPrizeRules.thirdPrize.amount,
      winnings: winnings,
    );
  }

  // ── Giải Tư: 5 số cuối, 7 kết quả ───────────────────────────

  static void _checkFourth(
    String ticket,
    Map<String, List<String>> results,
    List<WinningPrize> winnings,
  ) {
    _checkTailMatch(
      ticket: ticket,
      numbers: results['G4'] ?? [],
      digits: 5,
      prizeCode: 'G4',
      prizeName: XsmnPrizeRules.fourthPrize.name,
      amount: XsmnPrizeRules.fourthPrize.amount,
      winnings: winnings,
    );
  }

  // ── Giải Năm: 4 số cuối ─────────────────────────────────────

  static void _checkFifth(
    String ticket,
    Map<String, List<String>> results,
    List<WinningPrize> winnings,
  ) {
    _checkTailMatch(
      ticket: ticket,
      numbers: results['G5'] ?? [],
      digits: 4,
      prizeCode: 'G5',
      prizeName: XsmnPrizeRules.fifthPrize.name,
      amount: XsmnPrizeRules.fifthPrize.amount,
      winnings: winnings,
    );
  }

  // ── Giải Sáu: 4 số cuối, 3 kết quả ─────────────────────────

  static void _checkSixth(
    String ticket,
    Map<String, List<String>> results,
    List<WinningPrize> winnings,
  ) {
    _checkTailMatch(
      ticket: ticket,
      numbers: results['G6'] ?? [],
      digits: 4,
      prizeCode: 'G6',
      prizeName: XsmnPrizeRules.sixthPrize.name,
      amount: XsmnPrizeRules.sixthPrize.amount,
      winnings: winnings,
    );
  }

  // ── Giải Bảy: 3 số cuối ─────────────────────────────────────

  static void _checkSeventh(
    String ticket,
    Map<String, List<String>> results,
    List<WinningPrize> winnings,
  ) {
    _checkTailMatch(
      ticket: ticket,
      numbers: results['G7'] ?? [],
      digits: 3,
      prizeCode: 'G7',
      prizeName: XsmnPrizeRules.seventhPrize.name,
      amount: XsmnPrizeRules.seventhPrize.amount,
      winnings: winnings,
    );
  }

  // ── Giải Tám: 2 số cuối ─────────────────────────────────────

  static void _checkEighth(
    String ticket,
    Map<String, List<String>> results,
    List<WinningPrize> winnings,
  ) {
    _checkTailMatch(
      ticket: ticket,
      numbers: results['G8'] ?? [],
      digits: 2,
      prizeCode: 'G8',
      prizeName: XsmnPrizeRules.eighthPrize.name,
      amount: XsmnPrizeRules.eighthPrize.amount,
      winnings: winnings,
    );
  }

  // ── Helper: kiểm tra khớp N số cuối ─────────────────────────

  static void _checkTailMatch({
    required String ticket,
    required List<String> numbers,
    required int digits,
    required String prizeCode,
    required String prizeName,
    required int amount,
    required List<WinningPrize> winnings,
  }) {
    if (ticket.length < digits) return;
    final ticketTail = ticket.substring(ticket.length - digits);

    for (final raw in numbers) {
      final n = _clean(raw);
      if (n.length < digits) continue;
      final nTail = n.substring(n.length - digits);
      if (nTail == ticketTail) {
        winnings.add(WinningPrize(
          prizeCode: prizeCode,
          prizeName: prizeName,
          amount: amount,
          matchedNumber: n,
        ));
      }
    }
  }

  // ── Tiện ích ─────────────────────────────────────────────────

  static String _clean(String s) => s.trim();
}
