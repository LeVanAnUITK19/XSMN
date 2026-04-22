import 'package:flutter/material.dart';
import '../../../core/models/result_model.dart';

class ResultTable extends StatelessWidget {
  final List<ProvinceResult> provinces;
  final List<Map<String, dynamic>> tableData;

  const ResultTable({
    super.key,
    required this.provinces,
    required this.tableData,
  });

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
    if(isHeader == false && this.provinces.length > 3) {
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
        style:
            style ??
            TextStyle(
              // 👈 ưu tiên style truyền vào
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _cell(
                  'Giải',
                  isHeader: true,
                  fontSize: 12,
                  background: "gray",
                ),
              ),
              ...provinces.map(
                (p) => Expanded(
                  flex: 4,
                  child: _cell(
                    p.province,
                    isHeader: true,
                    fontSize: 14,
                    background: "gray", // 👈 nhỏ hơn
                  ),
                ),
              ),
            ],
          ),
        ),
        /// HEADER
       

        /// BODY
        Expanded(
          child: ListView.builder(
            itemCount: tableData.length,
            itemBuilder: (_, i) {
              final row = tableData[i];

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// label (G8, G7...)
                    Expanded(
                      flex: 2,
                      child: _cell(
                        row['label'],
                        isHeader: true,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    /// values
                    ...row['values'].map<Widget>((v) {
                      return Expanded(
                        flex: 4,
                        child: _cell(
                          v,
                          isG8: row['label'] == 'G8',
                          isDB: row['label'] == 'DB',
                        ),
                      );
                    }).toList(),
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
