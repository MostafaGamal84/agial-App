import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thin HTTP helper that mirrors the web app's /api contract and applies
/// the bearer token on authenticated calls.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
  })  : _http = httpClient ?? http.Client(),
        baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'https://localhost:7260/api',
            );

  final http.Client _http;
  final String baseUrl;
  String? _token;

  void updateToken(String? token) {
    _token = token;
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(
        isAuthenticated:
            path != '/Account/Login' && path != '/Account/VerifyCode',
      ),
      body: jsonEncode(body ?? {}),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters:
          query?.map((key, value) => MapEntry(key, '$value')),
    );
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
      if (decoded is Map<String, dynamic>) {
        if (decoded['isSuccess'] == true) {
          return decoded;
        } else if (decoded['isSuccess'] == false) {
          throw ApiException(
            message: _extractErrorMessage(decoded),
            errors: _parseErrors(decoded['errors']),
            statusCode: response.statusCode,
          );
        }
      }
      return decoded is Map<String, dynamic> ? decoded : {'result': decoded};
    }

    if (response.statusCode == 401) {
      throw ApiException(
        message: 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول снова',
        errors: [],
        statusCode: 401,
        isUnauthorized: true,
      );
    }

    throw ApiException(
      message: _extractErrorMessage(decoded),
      errors: _parseErrors(decoded['errors']),
      statusCode: response.statusCode,
    );
  }

  String _extractErrorMessage(Map<String, dynamic> decoded) {
    final errors = decoded['errors'] as List<dynamic>?;
    if (errors != null && errors.isNotEmpty) {
      final firstError = errors.first as Map<String, dynamic>;
      if (firstError['fieldLang'] != null && 
          (firstError['fieldLang'] as String).isNotEmpty) {
        return firstError['fieldLang'] as String;
      }
      return firstError['message']?.toString() ?? 'حدث خطأ غير متوقع';
    }
    return decoded['message']?.toString() ?? 'حدث خطأ غير متوقع';
  }

  List<ApiError> _parseErrors(dynamic errors) {
    if (errors == null) return [];
    if (errors is! List) return [];
    
    return errors.map((e) {
      final error = e as Map<String, dynamic>;
      return ApiError(
        fieldName: error['fieldName']?.toString(),
        code: error['code']?.toString(),
        message: error['message']?.toString(),
        fieldLang: error['fieldLang']?.toString(),
      );
    }).toList();
  }
}

class ApiException implements Exception {
  final String message;
  final List<ApiError> errors;
  final int statusCode;
  final bool isUnauthorized;

  ApiException({
    required this.message,
    required this.errors,
    required this.statusCode,
    this.isUnauthorized = false,
  });

  @override
  String toString() => message;
}

class ApiError {
  final String? fieldName;
  final String? code;
  final String? message;
  final String? fieldLang;

  ApiError({
    this.fieldName,
    this.code,
    this.message,
    this.fieldLang,
  });
}
