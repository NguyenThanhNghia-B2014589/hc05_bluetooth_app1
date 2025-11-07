// lib/services/settings_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService with ChangeNotifier {
  // Singleton
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  late SharedPreferences _prefs;

  // Giá trị cài đặt (mặc định là '7' ngày)
  String _historyRange = '7';

  // Getter để các Controller khác đọc
  String get historyRange => _historyRange;

  // Hàm khởi tạo (sẽ được gọi từ main.dart)
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Tải cài đặt đã lưu, nếu không có thì dùng '7'
    _historyRange = _prefs.getString('historyRange') ?? '7';
  }

  // Hàm cập nhật (sẽ được gọi từ SettingsScreen)
  Future<void> updateHistoryRange(String newRange) async {
    _historyRange = newRange;
    await _prefs.setString('historyRange', newRange);
    notifyListeners(); // Thông báo cho các Controller (History, Dashboard)
  }
}