import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

class StorageService {
  static final String baseUrl = '${dotenv.get('API_URL', fallback: 'http://localhost:8000')}/storage';
  final AuthService _authService = AuthService();

  Future<List<Map<String, dynamic>>> listFiles({String folder = ""}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/?folder=$folder'),
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

  Future<bool> createFolder(String name, {String currentFolder = ""}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/folder?folder=$currentFolder'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> uploadFile(String filePath, {String currentFolder = ""}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/file?folder=$currentFolder'));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

}
