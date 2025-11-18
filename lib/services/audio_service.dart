import 'package:flutter/services.dart';

/// Service để phát tiếng bíp khi cân thành công
/// Sử dụng HapticFeedback (rung điện thoại)
class AudioService {
  // Singleton
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  /// Phát tiếng bíp ngắn khi cân thành công
  Future<void> playSuccessBeep() async {
    try {
      // Rung điện thoại (mạnh)
      await HapticFeedback.heavyImpact();
    } catch (e) {
      // Bỏ qua nếu lỗi
    }
  }

  /// Phát tiếng bíp đôi (xác nhận thành công)
  Future<void> playDoubleBeep() async {
    try {
      // Bíp lần 1
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      // Bíp lần 2
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // Bỏ qua nếu lỗi
    }
  }

  /// Phát rung cảnh báo (lỗi)
  Future<void> playErrorVibration() async {
    try {
      await HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.vibrate();
    } catch (e) {
      // Bỏ qua nếu lỗi
    }
  }
}
