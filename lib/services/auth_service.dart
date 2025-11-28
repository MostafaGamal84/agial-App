import '../models/user.dart';
import 'mock_data_store.dart';

class AuthService {
  AuthService(this.dataStore);

  final MockDataStore dataStore;
  String? _pendingLogin;
  UserProfile? _currentUser;
  String? _token;

  UserProfile? get currentUser => _currentUser;
  String? get token => _token;

  Future<void> login(String login, {String? password}) async {
    if (!dataStore.loginDirectory.containsKey(login.trim().toLowerCase())) {
      throw Exception('البيانات غير صحيحة، جرّب بريدًا مسجلًا مثل admin@example.com');
    }
    _pendingLogin = login.trim().toLowerCase();
  }

  Future<UserProfile> verifyOtp(String otp) async {
    if (_pendingLogin == null) {
      throw Exception('ابدأ بتسجيل الدخول أولًا');
    }
    if (otp != '123456') {
      throw Exception('رمز التحقق غير صحيح');
    }
    final userId = dataStore.loginDirectory[_pendingLogin]!;
    _currentUser =
        dataStore.users.firstWhere((profile) => profile.id == userId);
    _token = 'mock-token-for-$userId';
    _pendingLogin = null;
    return _currentUser!;
  }

  void logout() {
    _currentUser = null;
    _token = null;
    _pendingLogin = null;
  }
}
