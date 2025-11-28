import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._authService);

  final AuthService _authService;
  bool isLoading = false;
  String? errorMessage;
  bool codeSent = false;

  UserProfile? get currentUser => _authService.currentUser;

  Future<void> login(String login, {String? password}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _authService.login(login, password: password);
      codeSent = true;
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<UserProfile?> verify(String otp) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final user = await _authService.verifyOtp(otp);
      codeSent = false;
      return user;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _authService.logout();
    notifyListeners();
  }
}
