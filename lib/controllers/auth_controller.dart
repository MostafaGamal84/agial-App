import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._authService) {
    _restoreSession();
  }

  final AuthService _authService;

  bool isLoading = false;
  bool isRestoring = true;
  String? errorMessage;

  UserProfile? get currentUser => _authService.currentUser;
  String? get pendingOtpCode => _authService.pendingOtpCode;

  Future<void> _restoreSession() async {
    await _authService.restoreSession();
    isRestoring = false;
    notifyListeners();
  }

  Future<UserProfile?> login(String login, {String? password}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final user = await _authService.login(login, password: password);
      return user;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<UserProfile?> verify(String otp) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      // 👈 مهم: auth_service.verifyOtp يرجّع UserProfile مبني من data اللي فيها role/branchId
      final user = await _authService.verifyOtp(otp);
      return user;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }
}
