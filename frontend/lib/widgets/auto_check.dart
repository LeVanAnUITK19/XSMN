import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../features/viewModels/home_viewmodel.dart';
import '../core/models/result_model.dart';

void showCheckTicketDialog(BuildContext context, ResultViewModel vm) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: Colors.yellow.shade50,
      child: _CheckTicketDialog(vm: vm),
    ),
  );
}

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
  bool _isLoading = false;

  // Kết quả dò
  List<_WinInfo>? _wins;
  String? _checkedNumber;

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
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
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
      _wins = null;
      _checkedNumber = null;
    });
  }

  void _checkTicket() {
    final digits = _controllers.map((c) => c.text.trim()).toList();
    if (digits.any((d) => d.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ 6 chữ số')),
      );
      return;
    }
    final number = digits.map((d) => d[0]).join();

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

    const prizeOrder = ['G8', 'G7', 'G6', 'G5', 'G4', 'G3', 'G2', 'G1', 'DB'];
    const prizeNames = {
      'G8': 'Giải Tám',
      'G7': 'Giải Bảy',
      'G6': 'Giải Sáu',
      'G5': 'Giải Năm',
      'G4': 'Giải Tư',
      'G3': 'Giải Ba',
      'G2': 'Giải Nhì',
      'G1': 'Giải Nhất',
      'DB': 'Giải Đặc Biệt',
    };

    final wins = <_WinInfo>[];
    for (final prize in prizeOrder) {
      for (final n in (province.full[prize] ?? <String>[])) {
        final clean = n.trim();
        if (clean.isEmpty) continue;
        final len = clean.length;
        final tail = len >= 6 ? clean.substring(len - 6) : clean;
        final offset = 6 - tail.length;
        if (tail == number.substring(offset)) {
          wins.add(_WinInfo(prize: prizeNames[prize] ?? prize, number: clean));
        }
      }
    }

    // Dò giải phụ Đặc Biệt
    for (final n in (province.full['DB'] ?? <String>[])) {
      final db = n.trim();
      if (db.length < 6) continue;

      // Giải phụ đặc biệt: 5 số cuối giống DB, sai số đầu
      final db5 = db.substring(db.length - 5);
      final ticket5 = number.substring(1); // 5 số cuối vé
      if (db5 == ticket5 && db[db.length - 6] != number[0]) {
        wins.add(_WinInfo(
          prize: 'Giải Phụ ĐB (~50tr)',
          number: db,
          note: '5 số cuối khớp, sai số đầu',
        ));
      }

      // Giải khuyến khích: sai đúng 1 số bất kỳ so với DB
      final db6 = db.substring(db.length - 6);
      int diffCount = 0;
      for (int k = 0; k < 6; k++) {
        if (db6[k] != number[k]) diffCount++;
      }
      if (diffCount == 1) {
        // Tránh trùng với giải chính hoặc giải phụ ĐB
        final alreadyWon = wins.any((w) => w.number == db && w.prize != 'Giải Phụ ĐB (~50tr)');
        final isMainWin = db6 == number;
        if (!alreadyWon && !isMainWin) {
          wins.add(_WinInfo(
            prize: 'Giải Khuyến Khích (~6tr)',
            number: db,
            note: 'Sai 1 số so với ĐB',
          ));
        }
      }
    }

    setState(() {
      _wins = wins;
      _checkedNumber = number;
    });
  }

  void _reset() {
    for (final c in _controllers) c.clear();
    setState(() {
      _wins = null;
      _checkedNumber = null;
    });
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    // Hiển thị màn kết quả nếu đã dò
    if (_wins != null && _checkedNumber != null) {
      return _buildResultView(context);
    }
    return _buildInputView(context);
  }

  Widget _buildResultView(BuildContext context) {
    final wins = _wins!;
    final number = _checkedNumber!;
    final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final isWin = wins.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isWin ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text(
            isWin ? '🎉 Chúc mừng!' : '😢 Không trúng',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            number,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$_selectedProvince  •  $dateStr',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          if (isWin)
            ...wins.map((w) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade400),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(w.prize,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            if (w.note != null)
                              Text(w.note!,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(w.number,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.red)),
                    ],
                  ),
                ))
          else
            Text(
              'Vé $number không trúng giải nào.\nChúc bạn may mắn lần sau!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  child: const Text('Dò tiếp'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
                  Text(dateStr,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Chọn tỉnh
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (_provinces.isEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.orange.shade50,
              ),
              child: const Text('Không có dữ liệu cho ngày này',
                  style: TextStyle(color: Colors.orange)),
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
                        _controllers[idx].text = value[value.length - 1];
                        _controllers[idx].selection =
                            const TextSelection.collapsed(offset: 1);
                      }
                      if (value.isNotEmpty && idx < 5) {
                        _focusNodes[idx + 1].requestFocus();
                        _controllers[idx + 1].selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: _controllers[idx + 1].text.length,
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
              child: const Text('Dò Vé',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _WinInfo {
  final String prize;
  final String number;
  final String? note;
  const _WinInfo({required this.prize, required this.number, this.note});
}
