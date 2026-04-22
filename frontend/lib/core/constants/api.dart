import 'dart:math';
import 'package:http/http.dart' as http;

class Api {
  static const baseUrl1 = 'https://xsmn.onrender.com/api/';
  static const baseUrl2 = 'https://xsmn-5jbi.onrender.com/api/';
  static final List<String> _bases = [baseUrl1, baseUrl2];
  static final Random _random = Random();

  // Hàm core để gọi API, tự động đổi server nếu sập
  static Future<http.Response> safeGet(String endpoint) async {
    int firstIndex = _random.nextInt(2);
    int secondIndex = 1 - firstIndex; // Server còn lại

    List<int> order = [firstIndex, secondIndex];

    for (int idx in order) {
      String url = "${_bases[idx]}$endpoint";
      try {
        print('📡 Đang thử kết nối: $url');
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
        
        // Nếu server sống (200-299) thì trả về luôn
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        print('⚠️ Server ${_bases[idx]} trả về lỗi ${response.statusCode}');
      } catch (e) {
        print('❌ Server ${_bases[idx]} không phản hồi: $e');
      }
    }
    throw Exception('Lỗi đường truyền!');
  }
}