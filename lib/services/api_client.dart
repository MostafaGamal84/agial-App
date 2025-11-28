import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin HTTP helper that mirrors the web app's /api contract and applies
/// the bearer token on authenticated calls.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
  })  : _http = httpClient ?? http.Client(),
        baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://example.com/api');

  final http.Client _http;
  final String baseUrl;
  String? _token;

  void updateToken(String? token) {
    _token = token;
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    final response = await _http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(isAuthenticated: path != '/Account/Login' && path != '/Account/VerifyCode'),
      body: jsonEncode(body ?? {}),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query?.map((key, value) => MapEntry(key, '$value')));
    final response = await _http.get(
      uri,
      headers: _headers(isAuthenticated: true),
    );
    return _decodeResponse(response);
  }

  Map<String, String> _headers({required bool isAuthenticated}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (isAuthenticated && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = response.body.isNotEmpty
        ? jsonDecode(utf8.decode(response.bodyBytes))
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded is Map<String, dynamic> ? decoded : {'result': decoded};
    }

    final message = decoded is Map<String, dynamic> && decoded['error'] != null
        ? decoded['error'].toString()
        : 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
    throw Exception(message);
  }
}
