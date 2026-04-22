import 'dart:convert';
import '../models/result_model.dart';
import '../constants/api.dart';

class ResultService {
  Future<List<LotteryResult>> getAll() async {
    final res = await Api.safeGet("results");

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => LotteryResult.fromJson(e)).toList();
    }

    throw Exception('API error: ${res.statusCode}');
  }

  Future<LotteryResult> getOne({
    required String date,
    required String region,
  }) async {
    final res = await Api.safeGet("results/filter?date=$date&region=$region");

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      if (data.isEmpty) throw Exception('No data found');

      final map = data.firstWhere(
        (e) => e['provinces'] != null && (e['provinces'] as List).isNotEmpty,
        orElse: () => data.first,
      );

      return LotteryResult.fromJson(map);
    }

    throw Exception('API error: ${res.statusCode}');
  }
}
