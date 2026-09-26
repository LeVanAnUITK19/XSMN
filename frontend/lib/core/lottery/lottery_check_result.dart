/// Data models cho kết quả dò vé số XSMN
library;

// ─────────────────────────────────────────────
// Trạng thái dữ liệu kết quả quay
// ─────────────────────────────────────────────

enum DataStatus {
  /// Đủ dữ liệu, có thể dò
  complete,

  /// Thiếu dữ liệu kết quả — KHÔNG được kết luận không trúng
  incomplete,

  /// Không tìm thấy dữ liệu cho ngày/đài này
  notFound,
}

// ─────────────────────────────────────────────
// Một giải trúng
// ─────────────────────────────────────────────

class WinningPrize {
  /// Mã giải: 'DB', 'DB_PHU', 'KK', 'G1' … 'G8'
  final String prizeCode;

  /// Tên hiển thị: 'Giải Đặc Biệt', 'Giải Phụ Đặc Biệt' …
  final String prizeName;

  /// Giá trị giải (VND)
  final int amount;

  /// Số trùng khớp trong bảng kết quả quay
  final String matchedNumber;

  /// Ghi chú bổ sung (ví dụ: "Trùng 5 số cuối, khác số đầu")
  final String? note;

  const WinningPrize({
    required this.prizeCode,
    required this.prizeName,
    required this.amount,
    required this.matchedNumber,
    this.note,
  });
}

// ─────────────────────────────────────────────
// Kết quả tổng hợp sau khi dò một vé
// ─────────────────────────────────────────────

class LotteryCheckResult {
  final String ticketNumber;
  final String station;
  final DateTime drawDate;

  /// true nếu trúng ít nhất một giải
  final bool isWinner;

  /// Danh sách TẤT CẢ các giải trúng (có thể nhiều giải)
  final List<WinningPrize> winnings;

  /// Tổng tiền thưởng trước thuế (VND)
  final int grossPrize;

  /// Phần chịu thuế (grossPrize - 20_000_000, tối thiểu 0)
  final int taxableAmount;

  /// Số thuế TNCN (taxableAmount × 10%)
  final int taxAmount;

  /// Thực nhận = grossPrize - taxAmount
  final int netPrize;

  /// Trạng thái dữ liệu kết quả quay
  final DataStatus dataStatus;

  /// Phiên bản cơ cấu giải đang áp dụng
  final String ruleVersion;

  /// Ngày kiểm chứng cơ cấu giải
  final String ruleLastVerifiedAt;

  const LotteryCheckResult({
    required this.ticketNumber,
    required this.station,
    required this.drawDate,
    required this.isWinner,
    required this.winnings,
    required this.grossPrize,
    required this.taxableAmount,
    required this.taxAmount,
    required this.netPrize,
    required this.dataStatus,
    this.ruleVersion = 'XSMN-2026.09',
    this.ruleLastVerifiedAt = '2026-09-26',
  });

  /// Tên giải cao nhất trong danh sách trúng (dùng để lưu lịch sử)
  String? get topPrizeName {
    if (winnings.isEmpty) return null;
    const rankOrder = [
      'DB', 'DB_PHU', 'G1', 'G2', 'G3', 'G4', 'G5', 'G6', 'G7', 'G8', 'KK',
    ];
    for (final code in rankOrder) {
      final found = winnings.where((w) => w.prizeCode == code);
      if (found.isNotEmpty) return found.first.prizeName;
    }
    return winnings.first.prizeName;
  }
}
