import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Service để phát tiếng bíp khi cân thành công
/// Sử dụng HapticFeedback + gọi native sound
class AudioService {
  // Singleton
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  static const platform = MethodChannel('com.hc.bluetooth.method_channel');
  static const audioChannel = MethodChannel('com.hc.audio.channel');

  /// Phát tiếng bíp ngắn khi cân thành công
  Future<void> playSuccessBeep() async {
    try {
      if (kDebugMode) print('🔊 Đang phát tiếng bíp thành công...');
      
      // 1. Phát rung (mạnh)
      await HapticFeedback.heavyImpact();
      if (kDebugMode) print('✅ Rung heavyImpact đã phát');

      // 2. Cố gắng gọi ToneGenerator qua native code
      try {
        await audioChannel.invokeMethod('playTone', {
          'type': 'TONE_CDMA_CONFIRM',
          'duration': 200
        });
        if (kDebugMode) print('✅ Âm thanh Tone đã phát');
      } catch (e) {
        if (kDebugMode) print('⚠️ ToneGenerator không hoạt động: $e');
      }

      // 3. Rung thêm lần nữa để tăng cảm nhận
      await Future.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.mediumImpact();
      if (kDebugMode) print('✅ Rung mediumImpact lần 2 đã phát');
      
    } catch (e) {
      if (kDebugMode) print('❌ Lỗi phát tiếng bíp: $e');
    }
  }

  /// Phát tiếng bíp đôi (xác nhận thành công)
  Future<void> playDoubleBeep() async {
    try {
      if (kDebugMode) print('🔊 Đang phát bíp đôi...');
      
      // Bíp lần 1
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      // Bíp lần 2
      await HapticFeedback.mediumImpact();
      
      if (kDebugMode) print('✅ Bíp đôi đã phát');
    } catch (e) {
      if (kDebugMode) print('❌ Lỗi phát bíp đôi: $e');
    }
  }

  /// Phát rung cảnh báo (lỗi)
  Future<void> playErrorVibration() async {
    try {
      if (kDebugMode) print('🔊 Đang phát rung cảnh báo...');
      
      await HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.vibrate();
      
      if (kDebugMode) print('✅ Rung cảnh báo đã phát');
    } catch (e) {
      if (kDebugMode) print('❌ Lỗi phát rung cảnh báo: $e');
    }
  }
}
