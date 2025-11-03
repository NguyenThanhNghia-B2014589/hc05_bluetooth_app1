import 'package:flutter/foundation.dart';

class AuthService with ChangeNotifier {
  // 1. Singleton (để đảm bảo chỉ có 1 service)
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // 2. State (Thông tin người dùng)
  String? _mUserID;
  String? _userName;

  // 3. Getters (để UI đọc)
  String? get mUserID => _mUserID;
  String? get userName => _userName;
  bool get isLoggedIn => _mUserID != null;

  // 4. Hàm Login (được gọi bởi LoginScreen)
  void login(String userID, String name) {
    _mUserID = userID;
    _userName = name;
    notifyListeners(); // Thông báo cho UI (AppBar) cập nhật
  }

  // 5. Hàm Logout (được gọi bởi AppBar)
  void logout() {
    _mUserID = null;
    _userName = null;
    notifyListeners(); // Thông báo cho UI (AppBar) cập nhật
  }
}