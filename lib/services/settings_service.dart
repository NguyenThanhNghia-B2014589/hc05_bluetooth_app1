// lib/services/settings_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService with ChangeNotifier {
  // Singleton
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  late SharedPreferences _prefs;

  // Giá trị cài đặt lịch sử (mặc định là '7' ngày)
  String _historyRange = '7';

  // Cài đặt tự động hoàn tất
  bool _autoCompleteEnabled = false;
  int _stabilizationDelay = 5; // Thời gian chờ cân ổn định (giây): 3, 5, 10
  int _autoCompleteDelay = 2; // Thời gian sau khi ổn định trước khi hoàn tất (giây)
  bool _beepOnSuccess = true; // Phát tiếng bíp khi cân thành công
  double _stabilityThreshold = 0.05; // Độ chênh lệch tối đa (kg) để coi là ổn định (mặc định 50g)

  // Getters
  String get historyRange => _historyRange;
  bool get autoCompleteEnabled => _autoCompleteEnabled;
  int get stabilizationDelay => _stabilizationDelay;
  int get autoCompleteDelay => _autoCompleteDelay;
  bool get beepOnSuccess => _beepOnSuccess;
  double get stabilityThreshold => _stabilityThreshold;

  // Hàm khởi tạo (sẽ được gọi từ main.dart)
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Tải cài đặt đã lưu
    _historyRange = _prefs.getString('historyRange') ?? '7';
    _autoCompleteEnabled = _prefs.getBool('autoCompleteEnabled') ?? false;
    _stabilizationDelay = _prefs.getInt('stabilizationDelay') ?? 5;
    _autoCompleteDelay = _prefs.getInt('autoCompleteDelay') ?? 2;
    _beepOnSuccess = _prefs.getBool('beepOnSuccess') ?? true;
    _stabilityThreshold = _prefs.getDouble('stabilityThreshold') ?? 0.05;
    
    // NOTE: Do not force-enable auto-complete - respect user's saved preference
  }

  // Cập nhật lịch sử
  Future<void> updateHistoryRange(String newRange) async {
    _historyRange = newRange;
    await _prefs.setString('historyRange', newRange);
    notifyListeners();
  }

  // Cập nhật tự động hoàn tất
  Future<void> updateAutoCompleteEnabled(bool enabled) async {
    _autoCompleteEnabled = enabled;
    await _prefs.setBool('autoCompleteEnabled', enabled);
    notifyListeners();
  }

  // Cập nhật thời gian ổn định (3, 5, 10 giây)
  Future<void> updateStabilizationDelay(int delay) async {
    if ([3, 5, 10].contains(delay)) {
      _stabilizationDelay = delay;
      await _prefs.setInt('stabilizationDelay', delay);
      notifyListeners();
    }
  }

  // Cập nhật thời gian hoàn tất (sau khi ổn định)
  Future<void> updateAutoCompleteDelay(int delay) async {
    _autoCompleteDelay = delay;
    await _prefs.setInt('autoCompleteDelay', delay);
    notifyListeners();
  }

  // Cập nhật bíp khi thành công
  Future<void> updateBeepOnSuccess(bool enabled) async {
    _beepOnSuccess = enabled;
    await _prefs.setBool('beepOnSuccess', enabled);
    notifyListeners();
  }

  // Cập nhật độ chênh lệch ổn định (kg)
  Future<void> updateStabilityThreshold(double threshold) async {
    if (threshold >= 0.01 && threshold <= 1.0) {
      _stabilityThreshold = threshold;
      await _prefs.setDouble('stabilityThreshold', threshold);
      notifyListeners();
    }
  }
}