import 'package:flutter/material.dart';

class ProvinceResult {
  final String province;
  final Map<String, List<String>> full;

  ProvinceResult({required this.province, required this.full});

  factory ProvinceResult.fromJson(Map<String, dynamic> json) {
    final fullMap = (json['full'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, List<String>.from(value)),
    );
    return ProvinceResult(
      province: json['province'],
      full: fullMap,
    );
  }
}

class LotteryResult {
  final String id;
  final DateTime date;
  final String region;
  final List<ProvinceResult> provinces;

  LotteryResult({
    required this.id,
    required this.date,
    required this.region,
    required this.provinces,
  });

  factory LotteryResult.fromJson(Map<String, dynamic> json) {
    return LotteryResult(
      id: json['_id'],
      date: DateTime.parse(json['date']),
      region: json['region'],
      provinces: (json['provinces'] as List)
          .map((p) => ProvinceResult.fromJson(p))
          .toList(),
    );
  }
}