import 'package:http/http.dart' as http;

class Api {
  // 192.168.15.31 → IP máy tính trên mạng LAN
  static const baseUrl = 'http://xsmn.onrender.com/api/results';

  static Future<http.Response> fetchProvinces() {
    return http.get(Uri.parse('$baseUrl/provinces'));
  }
}
