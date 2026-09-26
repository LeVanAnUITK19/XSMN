import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../features/viewModels/home_viewmodel.dart';
import '../core/models/result_model.dart';
import '../core/models/ticket_history_model.dart';
import '../core/services/database_service.dart';
import '../core/lottery/lottery_checker.dart';
import '../core/lottery/lottery_check_result.dart';

/// Mở dialog dò vé
void showCheckTicketDialog(BuildContext context, ResultViewModel vm) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: _CheckTicketDialog(vm: vm),
    ),
  );
}

// ─────────────────────────────────────────────
// Dialog chính
// ─────────────────────────────────────────────

class _CheckTicketDialog extends StatefulWidget {
  final ResultViewModel vm;
  const _CheckTicketDialog({required this.vm});

  @override
  State<_CheckTicketDialog> createState() => _CheckTicketDialogState();
}

class _CheckTicketDialogState extends State<_CheckTicketDialog> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late DateTime _selectedDate;
  String? _selectedProvince;
  LotteryResult? _dateResult;

  // Kết quả dò
  LotteryCheckResult? _checkResult;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.vm.currentDate;
    _dateResult = widget.vm.result;
    _selectedProvince = _dateResult?.provinces.isNotEmpty == true
        ? _dateResult!.provinces.first.province
        : null;
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  List<String> get _provinces =>
      _dateResult?.provinces.map((p) => p.province).toList() ?? [];

  void _onDateChanged(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final cached = widget.vm.getCache(key);
    setState(() {
      _selectedDate = date;
      _dateResult = cached;
      _selectedProvince = cached?.provinces.isNotEmpty == true
          ? cached!.provinces.first.province
          : null;
      _checkResult = null;
    });
  }

  Future<void> _checkTicket() async {
    // Ghép 6 chữ số — giữ nguyên số 0 đầu
    final digits = _controllers.map((c) => c.text.trim()).toList();
    if (digits.any((d) => d.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ 6 chữ số')),
      );
      return;
    }
    final number = digits.map((d) => d[0]).join(); // giữ chuỗi String

    if (_dateResult == null || _selectedProvince == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có dữ liệu cho ngày này')),
      );
      return;
    }

    final province = _dateResult!.provinces.firstWhere(
      (p) => p.province == _selectedProvince,
      orElse: () => _dateResult!.provinces.first,
    );

    // Gọi LotteryChecker — engine xử lý toàn bộ logic
    final result = LotteryChecker.check(
      ticketNumber: number,
      station: province.province,
      drawDate: _selectedDate,
      results: province.full,
    );

    setState(() {
      _checkResult = result;
    });

    // Lưu lịch sử
    final history = TicketHistory(
      ticketNumber: number,
      station: province.province,
      drawDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
      isWin: result.isWinner,
      prizeName: result.topPrizeName,
      grossPrize: result.grossPrize,
      taxAmount: result.taxAmount,
      netPrize: result.netPrize,
      checkedAt: DateTime.now(),
    );
    await DatabaseService.instance.insertTicketHistory(history);
  }

  void _reset() {
    for (final c in _controllers) {
      c.clear();
    }
    setState(() {
      _checkResult = null;
    });
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkResult != null) {
      return _buildResultView(context);
    }
    return _buildInputView(context);
  }

  // ─────────────────────────────────────────────
  // Màn hình nhập số vé
  // ─────────────────────────────────────────────

  Widget _buildInputView(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Dò Vé Số',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Chọn ngày
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                locale: const Locale('vi', 'VN'),
              );
              if (picked != null) _onDateChanged(picked);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    dateStr,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Chọn tỉnh
          if (_provinces.isEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.orange.shade50,
              ),
              child: const Text(
                'Không có dữ liệu cho ngày này',
                style: TextStyle(color: Colors.orange),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedProvince,
                  items: _provinces
                      .map((p) =>
                          DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedProvince = val),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // 6 ô nhập số
          Row(
            children: List.generate(11, (i) {
              if (i.isOdd) return const SizedBox(width: 6);
              final idx = i ~/ 2;
              return Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: TextField(
                    controller: _controllers[idx],
                    focusNode: _focusNodes[idx],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    onChanged: (value) {
                      if (value.length > 1) {
                        _controllers[idx].text =
                            value[value.length - 1];
                        _controllers[idx].selection =
                            const TextSelection.collapsed(offset: 1);
                      }
                      if (value.isNotEmpty && idx < 5) {
                        _focusNodes[idx + 1].requestFocus();
                        _controllers[idx + 1].selection = TextSelection(
                          baseOffset: 0,
                          extentOffset:
                              _controllers[idx + 1].text.length,
                        );
                      } else if (value.isEmpty && idx > 0) {
                        _focusNodes[idx - 1].requestFocus();
                      }
                    },
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _provinces.isEmpty ? null : _checkTicket,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Dò Vé',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Màn hình kết quả
  // ─────────────────────────────────────────────

  Widget _buildResultView(BuildContext context) {
    final r = _checkResult!;
    final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate);

    // Kết quả chưa đủ dữ liệu
    if (r.dataStatus == DataStatus.incomplete) {
      return _buildIncompleteDataView(context);
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                color: r.isWinner
                    ? Colors.green.shade50
                    : const Color(0xFFFFF0F0),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Text(
                    r.isWinner ? '🎉' : '😢',
                    style: const TextStyle(fontSize: 52),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    r.isWinner ? 'CHÚC MỪNG!' : 'CHƯA TRÚNG',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: r.isWinner
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      letterSpacing: 1,
                    ),
                  ),
                  if (r.isWinner && r.winnings.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Vé của bạn trúng ${r.winnings.length} giải',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Số vé
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      r.ticketNumber,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on,
                          size: 15, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        _selectedProvince ?? '',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500),
                      ),
                      Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 10),
                        width: 1,
                        height: 14,
                        color: Colors.grey.shade400,
                      ),
                      const Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Nội dung dưới ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                children: [
                  if (r.isWinner) ...[
                    // Danh sách từng giải trúng
                    ...r.winnings.map((w) => _WinningPrizeRow(prize: w)),
                    const SizedBox(height: 8),

                    // Divider + tổng kết
                    const Divider(height: 1, color: Colors.grey),
                    const SizedBox(height: 8),

                    // Tổng thưởng
                    _SummaryRow(
                      label: 'Tổng thưởng',
                      value: _fmt(r.grossPrize),
                      bold: true,
                    ),
                    if (r.taxAmount > 0) ...[
                      _SummaryRow(
                        label: 'Thuế TNCN dự kiến',
                        value: '- ${_fmt(r.taxAmount)}',
                        color: Colors.red.shade600,
                      ),
                      const Divider(height: 12, color: Colors.grey),
                      _SummaryRow(
                        label: 'Thực nhận dự kiến',
                        value: _fmt(r.netPrize),
                        bold: true,
                        color: Colors.green.shade700,
                        large: true,
                      ),
                    ] else ...[
                      _SummaryRow(
                        label: 'Thuế TNCN',
                        value: 'Không phát sinh',
                        color: Colors.grey.shade500,
                      ),
                      const Divider(height: 12, color: Colors.grey),
                      _SummaryRow(
                        label: 'Thực nhận dự kiến',
                        value: _fmt(r.netPrize),
                        bold: true,
                        color: Colors.green.shade700,
                        large: true,
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Ghi chú thuế
                    _TaxNote(taxableAmount: r.taxableAmount),
                  ] else ...[
                    // Không trúng
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Text(
                            'Vé ${r.ticketNumber} chưa trúng thưởng hôm nay.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Chúc bạn may mắn ở kỳ quay tiếp theo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Nút bấm
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _reset,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Dò tiếp'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Đóng'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hiển thị khi dữ liệu chưa đủ ───────────────────────────

  Widget _buildIncompleteDataView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_empty, size: 56, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            'Chưa thể dò vé',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Chưa thể dò vé vì kết quả kỳ quay chưa đầy đủ.\n'
            'Vui lòng thử lại sau khi có đủ kết quả.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Format tiền ─────────────────────────────────────────────

  String _fmt(int amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}đ';
  }
}

// ─────────────────────────────────────────────
// Widget phụ
// ─────────────────────────────────────────────

class _WinningPrizeRow extends StatelessWidget {
  final WinningPrize prize;

  const _WinningPrizeRow({required this.prize});

  @override
  Widget build(BuildContext context) {
    final isSpecial = prize.prizeCode == 'DB';
    final isSecondary = prize.prizeCode == 'DB_PHU';
    final accentColor = isSpecial
        ? Colors.red
        : isSecondary
            ? Colors.orange
            : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events, color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prize.prizeName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: accentColor.shade700,
                  ),
                ),
                if (prize.note != null)
                  Text(
                    prize.note!,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmt(prize.amount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              Text(
                prize.matchedNumber,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(int amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}đ';
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;
  final bool large;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: large ? 15 : 13,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: color ?? Colors.black87,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _TaxNote extends StatelessWidget {
  final int taxableAmount;

  const _TaxNote({required this.taxableAmount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        taxableAmount > 0
            ? 'Thuế TNCN theo quy định từ 01/07/2026: 10% × phần vượt 20 triệu. '
                'Số tiền thực nhận là dự kiến — đơn vị phát hành xổ số sẽ thực hiện '
                'khấu trừ khi thanh toán.'
            : 'Tổng giải thưởng ≤ 20 triệu đồng — không phát sinh thuế TNCN theo '
                'quy định từ 01/07/2026.',
        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.4),
      ),
    );
  }
}
