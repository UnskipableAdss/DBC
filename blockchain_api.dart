// lib/data/blockchain_api.dart
// ─────────────────────────────────────────────────────────────────────────────
// HTTP client for the Flask blockchain backend (sampbc.py)
// Base URL uses 10.0.2.2 which is localhost from inside the Android emulator
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart'

class BlockchainApi {
  // 10.0.2.2 = your PC's localhost as seen from the Android emulator
  static const String baseUrl = 'http://10.0.2.2:5000';

  static final _client = http.Client();

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ── GET /chain ─────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getChain() async {
    final res = await _client
        .get(Uri.parse('$baseUrl/chain'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    _check(res);
    final data = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(data);
  }

  // ── GET /chain_length ──────────────────────────────────────────────────────
  static Future<int> getChainLength() async {
    final res = await _client
        .get(Uri.parse('$baseUrl/chain_length'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    _check(res);
    return jsonDecode(res.body)['length'] as int;
  }

  // ── GET /block/<index> ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getBlock(int index) async {
    final res = await _client
        .get(Uri.parse('$baseUrl/block/$index'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    _check(res);
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  // ── GET /latest_block ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getLatestBlock() async {
    final res = await _client
        .get(Uri.parse('$baseUrl/latest_block'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    _check(res);
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  // ── GET /search/<student_id> ───────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> searchStudent(
      String studentId) async {
    final res = await _client
        .get(Uri.parse('$baseUrl/search/$studentId'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    _check(res);
    final data = jsonDecode(res.body);
    if (data is List) return List<Map<String, dynamic>>.from(data);
    return [];
  }

  // ── POST /add_block ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> addBlock({
    required String studentId,
    required String course,
    required int credits,
    required String creator,
  }) async {
    final res = await _client
        .post(
          Uri.parse('$baseUrl/add_block'),
          headers: _headers,
          body: jsonEncode({
            'student_id': studentId,
            'course': course,
            'credits': credits,
            'creator': creator,
          }),
        )
        .timeout(const Duration(seconds: 10));
    _check(res);
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  // ── GET /nodes ─────────────────────────────────────────────────────────────
  static Future<List<String>> getNodes() async {
    final res = await _client
        .get(Uri.parse('$baseUrl/nodes'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    _check(res);
    return List<String>.from(jsonDecode(res.body));
  }

  // ── POST /add_node ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> addNode(String node) async {
    final res = await _client
        .post(
          Uri.parse('$baseUrl/add_node'),
          headers: _headers,
          body: jsonEncode({'node': node}),
        )
        .timeout(const Duration(seconds: 10));
    _check(res);
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  // ── Status check ───────────────────────────────────────────────────────────
  static Future<bool> isReachable() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static void _check(http.Response res) {
    if (res.statusCode >= 400) {
      throw ApiException(
          'Server error ${res.statusCode}: ${res.reasonPhrase}');
    }
  }
}

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
