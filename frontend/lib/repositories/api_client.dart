import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// HTTP 402 — Free プランの使用制限に到達
class LimitException implements Exception {
  final String limitType; // 'messages' | 'goals'
  final int current;
  final int limit;

  const LimitException({
    required this.limitType,
    required this.current,
    required this.limit,
  });

  bool get isMessages => limitType == 'messages';
  bool get isGoals => limitType == 'goals';

  @override
  String toString() => 'LimitException($limitType: $current/$limit)';
}

class ApiClient {
  final String baseUrl;
  final Future<String?> Function()? _getToken;
  final http.Client _http;

  ApiClient({
    required this.baseUrl,
    Future<String?> Function()? getToken,
    http.Client? client,
  })  : _getToken = getToken,
        _http = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final token = await _getToken?.call();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path) async {
    final res = await _http.get(_uri(path), headers: await _headers());
    return _decode(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await _http.post(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final res = await _http.patch(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<void> delete(String path) async {
    final res = await _http.delete(_uri(path), headers: await _headers());
    if (res.statusCode < 200 || res.statusCode >= 300) {
      _throwIfLimit(res);
      throw ApiException(res.statusCode, res.body);
    }
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  dynamic _decode(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      _throwIfLimit(res);
      throw ApiException(res.statusCode, res.body);
    }
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  void _throwIfLimit(http.Response res) {
    if (res.statusCode != 402) return;
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['code'] == 'LIMIT_REACHED') {
        throw LimitException(
          limitType: body['limitType'] as String,
          current: body['current'] as int,
          limit: body['limit'] as int,
        );
      }
    } catch (e) {
      if (e is LimitException) rethrow;
    }
  }
}
