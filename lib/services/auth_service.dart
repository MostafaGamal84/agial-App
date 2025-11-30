// ===================================================
// AUTH SERVICE — FINAL VERSION
// ===================================================

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  AuthService(this._apiClient);

  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  String? _pendingLogin;
  String? _pendingOtpCode;
  UserProfile? _currentUser;
  String? _token;

  UserProfile? get currentUser => _currentUser;
  String? get token => _token;
  String? get pendingOtpCode => _pendingOtpCode;

  // ============================
  // RESTORE SESSION
  // ============================
  Future<void> restoreSession() async {
    final storedToken = await _secureStorage.read(key: _tokenKey);
    final storedUser = await _secureStorage.read(key: _userKey);

    if (storedToken == null || storedUser == null) return;

    final userMap = jsonDecode(storedUser) as Map<String, dynamic>;

    _token = storedToken;
    _currentUser = UserProfile.fromJson(userMap);
    _apiClient.updateToken(_token);
  }

  // ============================
  // LOGIN (step 1)
  // ============================
  Future<void> login(String login, {String? password}) async {
    _pendingOtpCode = null;
    final payload = {
      'email': login,
      if (password != null) 'password': password,
    };

    final response = await _apiClient.post('/Account/Login', body: payload);

    if (!_isSuccess(response)) {
      throw Exception(_extractError(response) ?? 'تعذر بدء تسجيل الدخول');
    }

    // لو عندك OTP: نخزن الإيميل مؤقتًا
    _pendingLogin = login;
    _pendingOtpCode = _extractOtpCode(response);

    // لو مستقبلاً حبيت تلغي الـ OTP وتاخد الـ token مباشرة من Login
    // تقدر تعدل هنا وتستدعي _extractUserProfile(response['data']) مباشرة.
  }

  // ============================
  // VERIFY OTP (step 2)
  // ============================
  Future<UserProfile> verifyOtp(String otp) async {
    if (_pendingLogin == null) {
      throw Exception('ابدأ بتسجيل الدخول أولًا');
    }

    final response = await _apiClient.post(
      '/Account/VerifyCode',
      body: {
        'email': _pendingLogin,
        'code': otp,
      },
    );

    if (!_isSuccess(response)) {
      throw Exception(_extractError(response) ?? 'رمز التحقق غير صحيح');
    }

    final result = _extractResultMap(response);

    final profile = _extractUserProfile(result);

    final token = result['accessToken']?.toString() ??
        result['token']?.toString();

    if (token == null) {
      throw Exception('تعذر التحقق من الرمز');
    }

    _currentUser = profile;
    _token = token;
    _pendingLogin = null;
    _pendingOtpCode = null;

    _apiClient.updateToken(_token);

    await _persistSession();

    return profile;
  }

  // ============================
  // LOGOUT
  // ============================
  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    _pendingLogin = null;
    _pendingOtpCode = null;

    _apiClient.updateToken(null);

    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userKey);
  }

  // ============================
  // SAVE SESSION
  // ============================
  Future<void> _persistSession() async {
    if (_token == null || _currentUser == null) return;

    await _secureStorage.write(key: _tokenKey, value: _token);
    await _secureStorage.write(
      key: _userKey,
      value: jsonEncode(_currentUser!.toJson()),
    );
  }

  // ============================
  // HELPERS
  // ============================
  bool _isSuccess(Map<String, dynamic> response) {
    final directSuccess = response['success'];
    final altSuccess = response['isSuccess'];

    if (directSuccess is bool) return directSuccess;
    if (altSuccess is bool) return altSuccess;

    return true;
  }

  String? _extractError(Map<String, dynamic> response) {
    if (response['error'] != null) {
      return response['error'].toString();
    }

    final errors = response['errors'];
    if (errors is List && errors.isNotEmpty) {
      return errors.first.toString();
    }

    return null;
  }

  Map<String, dynamic> _extractResultMap(Map<String, dynamic> response) {
    final result = response['result'] ?? response['data'];
    if (result is Map<String, dynamic>) return result;

    throw Exception('استجابة غير متوقعة من الخادم');
  }

  String? _extractOtpCode(Map<String, dynamic> response) {
    final result = response['data'] ?? response['result'];
    if (result is Map<String, dynamic> && result['code'] != null) {
      return result['code'].toString();
    }
    return null;
  }

  // ===================================================
  // USER PARSING (باستخدام role و branchId من الـ API)
  // ===================================================
  UserProfile _extractUserProfile(Map<String, dynamic> payload) {
    final token = payload['accessToken']?.toString() ??
        payload['token']?.toString();

    final roleId = payload['role']?.toString();
    final branchId = payload['branchId']?.toString() ?? '0';

    String? userId;
    String? fullName;

    if (token != null) {
      final claims = _decodeJwtPayload(token);

      userId = claims['sub']?.toString() ??
          claims['nameid']?.toString() ??
          payload['userId']?.toString();

      fullName = claims['name']?.toString() ??
          claims['unique_name']?.toString() ??
          payload['username']?.toString();
    }

    return UserProfile(
      id: userId ?? payload['userId']?.toString() ?? '0',
      fullName: fullName ?? payload['username']?.toString() ?? "مستخدم",
      userType: UserType.fromRoleId(roleId),
      branchId: branchId,
      managerId: payload['managerId']?.toString(),
    );
  }

  Map<String, dynamic> _decodeJwtPayload(String token) {
    final segments = token.split('.');
    if (segments.length < 2) return {};

    try {
      final normalized = base64Url.normalize(segments[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(payload);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }
}
