import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

class NotificationService {
  static final String baseUrl = '${dotenv.get('API_URL', fallback: 'http://localhost:8000')}/notifications';
  final AuthService _authService = AuthService();

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
