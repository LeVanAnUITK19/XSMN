import '../models/result_model.dart';

List<Map<String, dynamic>> transformData(
  List<ProvinceResult> provinces,
  String filter, // 'full' | '3' | '2'
) {
  final prizes = ['G8', 'G7', 'G6', 'G5', 'G4', 'G3', 'G2', 'G1', 'DB'];

  return prizes.map((prize) {
    return {
      'label': prize,
      'values': provinces.map((p) {
        final list = p.full[prize] ?? [];

        final filtered = list.map((e) {
          if (filter == '3' && e.length >= 3) {
            return e.substring(e.length - 3);
          }
          if (filter == '2' && e.length >= 2) {
            return e.substring(e.length - 2);
          }
          return e;
        }).toList();

        return filtered.join('\n');
      }).toList(),
    };
  }).toList();
}
