// lib/data/auth_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:edi_translator/data/auth_model.dart';
import 'package:edi_translator/data/blockchain_api.dart';

class AuthApi {
  static const _base = BlockchainApi.baseUrl;
  static final _client = http.Client();
  static const _headers = {'Content-Type': 'application/json'};

  /// Returns [UserSession] on success, throws [ApiException] on failure.
  static Future<UserSession> login({
    required String role,   // "student" or "admin"
    required String username,
    required String password,
  }) async {
    final res = await _client
        .post(
          Uri.parse('$_base/login'),
          headers: _headers,
          body: jsonEncode({
            'role': role,
            'username': username,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return UserSession.fromJson(data);
    }
    throw ApiException(data['message'] ?? 'Login failed.');
  }

  /// Register a new student account.
  static Future<String> registerStudent({
    required String studentId,
    required String password,
    required String university,
  }) async {
    final res = await _client
        .post(
          Uri.parse('$_base/register/student'),
          headers: _headers,
          body: jsonEncode({
            'student_id': studentId,
            'password': password,
            'university': university,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] == true) return data['message'] ?? 'Registered.';
    throw ApiException(data['message'] ?? 'Registration failed.');
  }
}
