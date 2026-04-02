import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/result_model.dart';
import '../constants/api.dart';

class ResultService {
  Future<LotteryResult> getOne({
    required String date,
    required String region,
  }) async {
    final uri = Uri.parse('${Api.baseUrl}/filter').replace(queryParameters: {
      'date': date,
      'region': region,
    });

    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      if (data.isEmpty) throw Exception('No data found');

      // Ưu tiên document có provinces không rỗng
      final map = data.firstWhere(
        (e) => e['provinces'] != null && (e['provinces'] as List).isNotEmpty,
        orElse: () => data.first,
      );

      return LotteryResult.fromJson(map);
    }

    throw Exception('API error');
  }
}