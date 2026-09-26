/// Tính thuế Thu nhập cá nhân (TNCN) cho xổ số
///
/// Căn cứ pháp lý:
/// - Luật Thuế thu nhập cá nhân hiện hành
/// - Nghị định 253/2026/NĐ-CP
/// - Thông tư 87/2026/TT-BTC
/// Hiệu lực từ: 01/07/2026
///
/// Ngưỡng tính thuế: 20.000.000đ / vé / kỳ quay
/// Thuế suất: 10% trên phần vượt ngưỡng
///
/// LƯU Ý: Nếu một vé trúng nhiều giải, CỘNG TỔNG tất cả giải
/// của vé TRƯỚC KHI tính thuế. Không tính thuế riêng từng giải.
library;

class TaxCalculator {
  TaxCalculator._();

  /// Ngưỡng miễn thuế TNCN (VND) — áp dụng từ 01/07/2026
  static const int taxThreshold = 20000000;

  /// Thuế suất TNCN xổ số
  static const double taxRate = 0.10;

  /// Tính thuế từ tổng giải thưởng gộp của một vé / một kỳ quay
  ///
  /// [grossPrize] — tổng tiền thưởng (đã cộng tất cả giải của vé)
  /// Trả về [TaxResult] gồm: taxableAmount, taxAmount, netPrize
  static TaxResult calculate(int grossPrize) {
    final taxableAmount = grossPrize > taxThreshold
        ? grossPrize - taxThreshold
        : 0;
    final taxAmount = (taxableAmount * taxRate).round();
    final netPrize = grossPrize - taxAmount;

    return TaxResult(
      grossPrize: grossPrize,
      taxableAmount: taxableAmount,
      taxAmount: taxAmount,
      netPrize: netPrize,
    );
  }
}

class TaxResult {
  final int grossPrize;
  final int taxableAmount;
  final int taxAmount;
  final int netPrize;

  const TaxResult({
    required this.grossPrize,
    required this.taxableAmount,
    required this.taxAmount,
    required this.netPrize,
  });
}
