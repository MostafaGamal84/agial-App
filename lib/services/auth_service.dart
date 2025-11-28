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
  UserProfile? _currentUser;
  String? _token;

  UserProfile? get currentUser => _currentUser;
  String? get token => _token;

  Future<void> restoreSession() async {
    final storedToken = await _secureStorage.read(key: _tokenKey);
    final storedUser = await _secureStorage.read(key: _userKey);
    if (storedToken == null || storedUser == null) return;

    final userMap = jsonDecode(storedUser) as Map<String, dynamic>;
    _token = storedToken;
    _currentUser = UserProfile.fromApi(userMap);
    _apiClient.updateToken(_token);
  }

  Future<void> login(String login, {String? password}) async {
    final payload = {
      'email': login,
      if (password != null) 'password': password,
    };
    final response = await _apiClient.post('/Account/Login', body: payload);
    if (response['success'] == false) {
      throw Exception(response['error'] ?? 'تعذر بدء تسجيل الدخول');
    }
    _pendingLogin = login;
  }

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
    if (response['success'] == false) {
      throw Exception(response['error'] ?? 'رمز التحقق غير صحيح');
    }
    final result = response['result'] as Map<String, dynamic>?;
    if (result == null || result['accessToken'] == null) {
      throw Exception('تعذر التحقق من الرمز');
    }
    final profile = UserProfile.fromApi(result);
    _currentUser = profile;
    _token = result['accessToken'] as String?;
    _pendingLogin = null;
    _apiClient.updateToken(_token);
    await _persistSession();
    return profile;
  }

  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    _pendingLogin = null;
    _apiClient.updateToken(null);
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userKey);
  }

  Future<void> _persistSession() async {
    if (_token == null || _currentUser == null) return;
    await _secureStorage.write(key: _tokenKey, value: _token);
    await _secureStorage.write(key: _userKey, value: jsonEncode(_currentUser!.toJson()));
  }
}
