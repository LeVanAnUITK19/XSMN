/// Cấu hình cơ cấu giải thưởng XSMN truyền thống
///
/// Nguồn tham khảo chính thức:
/// - Website chính thức Công ty TNHH MTV XSKT Tây Ninh
///   (https://xosotayninh.com.vn/trung-thuong/co-cau-giai-thuong)
/// - Thể lệ tham gia dự thưởng xổ số truyền thống miền Nam
///
/// Ngày kiểm chứng: 26/09/2026
/// Phiên bản: XSMN-2026.09
library;

class PrizeRule {
  /// Mã giải
  final String code;

  /// Tên hiển thị
  final String name;

  /// Giá trị (VND)
  final int amount;

  /// Số chữ số cần khớp ở CUỐI vé
  /// - 6 → khớp toàn bộ (Đặc Biệt)
  /// - 5 → 5 số cuối
  /// - 4 → 4 số cuối
  /// - 3 → 3 số cuối
  /// - 2 → 2 số cuối
  final int matchDigits;

  /// Số lượng kết quả quay trong một đợt
  /// (G3 = 2, G4 = 7, G6 = 3, còn lại = 1)
  final int resultCount;

  /// Số vé trúng trên 1.000.000 vé / series
  final int winnersPerSeries;

  /// Mô tả ngắn điều kiện trúng
  final String condition;

  const PrizeRule({
    required this.code,
    required this.name,
    required this.amount,
    required this.matchDigits,
    required this.resultCount,
    required this.winnersPerSeries,
    required this.condition,
  });
}

/// Toàn bộ cơ cấu giải XSMN hiện hành
/// Thứ tự: từ Đặc Biệt → Tám (để engine kiểm tra tuần tự)
class XsmnPrizeRules {
  XsmnPrizeRules._();

  static const String ruleVersion = 'XSMN-2026.09';
  static const String ruleLastVerifiedAt = '2026-09-26';
  static const String officialSource = 'Công ty TNHH MTV XSKT Tây Ninh — xosotayninh.com.vn';

  // ── Giải chính ──────────────────────────────────────────────

  static const PrizeRule specialPrize = PrizeRule(
    code: 'DB',
    name: 'Giải Đặc Biệt',
    amount: 2000000000,
    matchDigits: 6,
    resultCount: 1,
    winnersPerSeries: 1,
    condition: 'Trùng đủ 6 số',
  );

  static const PrizeRule firstPrize = PrizeRule(
    code: 'G1',
    name: 'Giải Nhất',
    amount: 30000000,
    matchDigits: 5,
    resultCount: 1,
    winnersPerSeries: 10,
    condition: 'Trùng 5 số cuối',
  );

  static const PrizeRule secondPrize = PrizeRule(
    code: 'G2',
    name: 'Giải Nhì',
    amount: 15000000,
    matchDigits: 5,
    resultCount: 1,
    winnersPerSeries: 10,
    condition: 'Trùng 5 số cuối',
  );

  static const PrizeRule thirdPrize = PrizeRule(
    code: 'G3',
    name: 'Giải Ba',
    amount: 10000000,
    matchDigits: 5,
    resultCount: 2,
    winnersPerSeries: 20,
    condition: 'Trùng 5 số cuối (2 kết quả)',
  );

  static const PrizeRule fourthPrize = PrizeRule(
    code: 'G4',
    name: 'Giải Tư',
    amount: 3000000,
    matchDigits: 5,
    resultCount: 7,
    winnersPerSeries: 70,
    condition: 'Trùng 5 số cuối (7 kết quả)',
  );

  static const PrizeRule fifthPrize = PrizeRule(
    code: 'G5',
    name: 'Giải Năm',
    amount: 1000000,
    matchDigits: 4,
    resultCount: 1,
    winnersPerSeries: 100,
    condition: 'Trùng 4 số cuối',
  );

  static const PrizeRule sixthPrize = PrizeRule(
    code: 'G6',
    name: 'Giải Sáu',
    amount: 400000,
    matchDigits: 4,
    resultCount: 3,
    winnersPerSeries: 300,
    condition: 'Trùng 4 số cuối (3 kết quả)',
  );

  static const PrizeRule seventhPrize = PrizeRule(
    code: 'G7',
    name: 'Giải Bảy',
    amount: 200000,
    matchDigits: 3,
    resultCount: 1,
    winnersPerSeries: 1000,
    condition: 'Trùng 3 số cuối',
  );

  static const PrizeRule eighthPrize = PrizeRule(
    code: 'G8',
    name: 'Giải Tám',
    amount: 100000,
    matchDigits: 2,
    resultCount: 1,
    winnersPerSeries: 10000,
    condition: 'Trùng 2 số cuối',
  );

  // ── Giải phụ / đặc biệt ─────────────────────────────────────

  /// Giải Phụ Đặc Biệt: 9 giải × 50.000.000đ
  /// Điều kiện: 5 số CUỐI giống Đặc Biệt, số ĐẦU khác
  static const specialSecondaryPrize = (
    code: 'DB_PHU',
    name: 'Giải Phụ Đặc Biệt',
    amount: 50000000,
    count: 9,
    condition: 'Trùng 5 số cuối Giải Đặc Biệt, khác số đầu',
  );

  /// Giải Khuyến Khích: 45 giải × 6.000.000đ
  /// Điều kiện: Số đầu giống Đặc Biệt, sai đúng 1 trong 5 số còn lại
  static const encouragementPrize = (
    code: 'KK',
    name: 'Giải Khuyến Khích',
    amount: 6000000,
    count: 45,
    condition: 'Giống số đầu Giải Đặc Biệt, sai đúng 1 trong 5 số còn lại',
  );

  /// Số lượng kết quả tối thiểu cần có để dò vé hợp lệ
  /// G8:1, G7:1, G6:3, G5:1, G4:7, G3:2, G2:1, G1:1, DB:1 → tổng 18
  static const int minimumResultCount = 18;

  /// Map số lượng kết quả tối thiểu theo key của API
  static const Map<String, int> requiredResultCounts = {
    'G8': 1,
    'G7': 1,
    'G6': 3,
    'G5': 1,
    'G4': 7,
    'G3': 2,
    'G2': 1,
    'G1': 1,
    'DB': 1,
  };

  /// Danh sách tất cả giải chính theo thứ tự kiểm tra
  static const List<PrizeRule> allMainPrizes = [
    specialPrize,
    firstPrize,
    secondPrize,
    thirdPrize,
    fourthPrize,
    fifthPrize,
    sixthPrize,
    seventhPrize,
    eighthPrize,
  ];
}
