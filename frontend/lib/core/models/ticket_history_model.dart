/// Model lịch sử dò vé — lưu trong SQLite
class TicketHistory {
  final int? id;
  final String ticketNumber; // 6 chữ số (String, giữ số 0 đầu)
  final String station; // tên tỉnh/đài
  final String drawDate; // yyyy-MM-dd
  final bool isWin; // true = trúng
  final String? prizeName; // tên giải cao nhất nếu trúng
  final int grossPrize; // tổng tiền thưởng (VND)
  final int taxAmount; // thuế TNCN (VND)
  final int netPrize; // thực nhận sau thuế (VND)
  final DateTime checkedAt; // thời điểm dò

  const TicketHistory({
    this.id,
    required this.ticketNumber,
    required this.station,
    required this.drawDate,
    required this.isWin,
    this.prizeName,
    this.grossPrize = 0,
    this.taxAmount = 0,
    this.netPrize = 0,
    required this.checkedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'ticketNumber': ticketNumber,
      'station': station,
      'drawDate': drawDate,
      'isWin': isWin ? 1 : 0,
      'prizeName': prizeName,
      'grossPrize': grossPrize,
      'taxAmount': taxAmount,
      'netPrize': netPrize,
      'checkedAt': checkedAt.toIso8601String(),
    };
  }

  factory TicketHistory.fromMap(Map<String, dynamic> map) {
    return TicketHistory(
      id: map['id'] as int?,
      ticketNumber: map['ticketNumber'] as String,
      station: map['station'] as String,
      drawDate: map['drawDate'] as String,
      isWin: (map['isWin'] as int) == 1,
      prizeName: map['prizeName'] as String?,
      grossPrize: (map['grossPrize'] as int?) ?? 0,
      taxAmount: (map['taxAmount'] as int?) ?? 0,
      netPrize: (map['netPrize'] as int?) ?? 0,
      checkedAt: DateTime.parse(map['checkedAt'] as String),
    );
  }
}
