import 'package:http/http.dart' as http;

class Api {
  static const _baseUrl = 'https://long-queen-5b3a.levanan1902006.workers.dev/api/';

  static Future<http.Response> safeGet(String endpoint) async {
    final url = '$_baseUrl$endpoint';
    print('📡 Đang kết nối: $url');
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 8));
    return response;
  }
}
