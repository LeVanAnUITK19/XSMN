import 'package:flutter/material.dart';
import '../../../core/models/result_model.dart';

/// Bảng kết quả xổ số.
/// Hỗ trợ phóng to từng cột tỉnh (zoom mode) — chỉ thay đổi UI,
/// không gọi API hay thay đổi cấu trúc dữ liệu.
class ResultTable extends StatefulWidget {
  final List<ProvinceResult> provinces;
  final List<Map<String, dynamic>> tableData;

  const ResultTable({
    super.key,
    required this.provinces,
    required this.tableData,
  });

  @override
  State<ResultTable> createState() => _ResultTableState();
}

class _ResultTableState extends State<ResultTable> {
  /// Index của cột đang được zoom (-1 = không zoom)
  int _zoomedIndex = -1;

  bool get _isZoomed => _zoomedIndex >= 0;

  // ── Cell builder ───────────────────────────────────────────────

  Widget _cell(
    String text, {
    bool isHeader = false,
    bool isG8 = false,
    bool isDB = false,
    double fontSize = 18,
    String background = 'white',
    TextStyle? style,
  }) {
    double finalFontSize = text == 'Đang cập nhật' ? 14 : fontSize;
    // Khi zoom thì tăng font size
    if (_isZoomed && !isHeader) {
      finalFontSize = 22;
    } else if (!isHeader && widget.provinces.length > 3) {
      finalFontSize = 16;
    }

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: style ??
            TextStyle(
              fontSize: finalFontSize,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.w900,
              backgroundColor: background == 'white'
                  ? Colors.white
                  : Colors.yellow.shade100,
              color: isG8 || isDB ? Colors.red : Colors.black,
            ),
      ),
    );
  }

  // ── Header tên tỉnh + nút zoom ──────────────────────────────

  Widget _provinceHeader(ProvinceResult p, int index) {
    final isThisZoomed = _zoomedIndex == index;

    return Expanded(
      flex: 4,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _zoomedIndex = isThisZoomed ? -1 : index;
          });
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            color: isThisZoomed
                ? Colors.yellow.shade200
                : Colors.yellow.shade100,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  p.province,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isThisZoomed
                        ? const Color.fromARGB(255, 200, 10, 0)
                        : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isThisZoomed ? Icons.zoom_out : Icons.zoom_in,
                size: 16,
                color: isThisZoomed
                    ? const Color.fromARGB(255, 200, 10, 0)
                    : Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Nút "Thu nhỏ / Quay lại" ───────────────────────────────

  Widget _zoomBanner() {
    final provinceName = widget.provinces[_zoomedIndex].province;
    return Container(
      color: Colors.yellow.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.zoom_out_map, size: 16, color: Colors.black54),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Đang phóng to: $provinceName',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton.icon(
            onPressed: () => setState(() => _zoomedIndex = -1),
            icon: const Icon(Icons.fullscreen_exit, size: 16),
            label: const Text('Thu nhỏ'),
            style: TextButton.styleFrom(
              foregroundColor: const Color.fromARGB(255, 200, 10, 0),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Banner khi đang zoom
        if (_isZoomed) _zoomBanner(),

        // Header hàng tên tỉnh
        IntrinsicHeight(
          child: Row(
            children: [
              // Cột "Giải"
              Expanded(
                flex: 2,
                child: _cell(
                  'Giải',
                  isHeader: true,
                  fontSize: 12,
                  background: 'gray',
                ),
              ),
              // Cột tỉnh — nếu đang zoom chỉ render tỉnh đó
              if (_isZoomed)
                _provinceHeader(
                    widget.provinces[_zoomedIndex], _zoomedIndex)
              else
                ...widget.provinces.asMap().entries.map(
                      (e) => _provinceHeader(e.value, e.key),
                    ),
            ],
          ),
        ),

        // Body
        Expanded(
          child: ListView.builder(
            itemCount: widget.tableData.length,
            itemBuilder: (_, i) {
              final row = widget.tableData[i];

              // Lọc values theo cột đang zoom
              final values = _isZoomed
                  ? [row['values'][_zoomedIndex]]
                  : row['values'] as List;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Label
                    Expanded(
                      flex: 2,
                      child: _cell(
                        row['label'],
                        isHeader: true,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    // Values
                    ...values.map<Widget>((v) {
                      return Expanded(
                        flex: 4,
                        child: _cell(
                          v,
                          isG8: row['label'] == 'G8',
                          isDB: row['label'] == 'DB',
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
