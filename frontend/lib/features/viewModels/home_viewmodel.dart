import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/result_model.dart';
import '../../../core/services/result_service.dart';
import '../../../core/services/cache_service.dart';

class ResultViewModel extends ChangeNotifier {
  final _service = ResultService();
  final Map<String, LotteryResult> _cache = {};

  LotteryResult? result;
  bool isLoading = true;   // true ngay từ đầu → hiện WaitPage ngay, không flash màn trắng
  bool isRefreshing = false;
  String? error;
  bool notFound = false;

  DateTime currentDate = DateTime.now();

  static const _cacheKey = 'results_all';

  Future<void> load() async {
    error = null;

    // ── Bước 1: Thử load local cache ─────────────────────────────
    final cached = await CacheService.get(
      _cacheKey,
      maxAge: const Duration(hours: 12),
    );

    if (cached != null) {
      // Có cache → parse ngay, tắt loading, vào home luôn
      _parseAndCache(cached);
      _showClosestDate();
      isLoading = false;    // ← tắt WaitPage ngay lập tức
      isRefreshing = true;  // ← bật banner "Đang tải mới..."
      notifyListeners();

      // Fetch mới ở background
      await _fetchFromApi(background: true);
    } else {
      // Không có cache → giữ WaitPage, fetch bình thường
      isLoading = true;
      notifyListeners();
      await _fetchFromApi(background: false);
    }
  }

  Future<void> _fetchFromApi({required bool background}) async {
    try {
      final all = await _service.getAll();

      final jsonList = all.map((e) => e.toJson()).toList();
      await CacheService.save(_cacheKey, jsonEncode(jsonList));

      _cache.clear();
      for (final item in all) {
        if (item.provinces.isNotEmpty) {
          final key = DateFormat('yyyy-MM-dd').format(item.date.toLocal());
          _cache[key] = item;
        }
      }

      _showClosestDate();
      error = null;
    } catch (e) {
      if (!background) {
        error = 'Không thể tải dữ liệu: $e';
      }
      // background fail → giữ data cũ, không báo lỗi
    }

    isLoading = false;
    isRefreshing = false;
    notifyListeners();
  }

  void _parseAndCache(String jsonStr) {
    try {
      final List data = jsonDecode(jsonStr);
      _cache.clear();
      for (final item in data) {
        final r = LotteryResult.fromJson(item);
        if (r.provinces.isNotEmpty) {
          final key = DateFormat('yyyy-MM-dd').format(r.date.toLocal());
          _cache[key] = r;
        }
      }
    } catch (_) {
      // Cache corrupt → bỏ qua, fetch mới
    }
  }

  void _showClosestDate() {
    final today = DateFormat('yyyy-MM-dd').format(currentDate);
    if (_cache.containsKey(today)) {
      result = _cache[today];
      return;
    }
    if (_cache.isNotEmpty) {
      final sorted = _cache.keys.toList()..sort();
      final latest = sorted.last;
      currentDate = DateTime.parse(latest);
      result = _cache[latest];
    }
  }

  LotteryResult? getCache(String key) => _cache[key];

  void loadByDate(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    if (_cache.containsKey(key)) {
      currentDate = date;
      result = _cache[key];
      notFound = false;
    } else {
      notFound = true;
    }
    notifyListeners();
  }
}
