import 'dart:convert';
import '../models/result_model.dart';
import '../constants/api.dart';

class ResultService {
  Future<List<LotteryResult>> getAll() async {
    final res = await Api.safeGet("results");

    print('📥 API status: ${res.statusCode}');
    print('📥 API body (first 200 chars): ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}');

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final List data = body is List ? body : (body['data'] as List);
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
      final body = jsonDecode(res.body);
      final List data = body is List ? body : (body['data'] as List);

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
