import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service theo dõi tính ổn định của trọng lượng từ cân Bluetooth
/// Gọi callback khi trọng lượng ổn định trong khoảng thời gian xác định
class WeightStabilityMonitor {
  // Callback được gọi khi cân ổn định
  VoidCallback? onStable;

  // Danh sách các giá trị trọng lượng gần đây
  final List<double> _recentWeights = [];

  // Thời gian chờ cân ổn định (giây) - do SettingsService cung cấp
  int _stabilizationDelay;

  // Độ chênh lệch tối đa để coi là ổn định (kg)
  static const double _stabilityThreshold = 0.05; // 0.05 kg = 50g (từ 20g → 50g)

  // Timer để kiểm tra định kỳ
  Timer? _checkTimer;
  
  // Trạng thái ổn định trước đó (để tránh gọi callback nhiều lần)
  bool _wasStable = false;

  WeightStabilityMonitor({
    required int stabilizationDelay,
    this.onStable,
  }) : _stabilizationDelay = stabilizationDelay {
    // Bắt đầu timer kiểm tra ổn định
    _startCheckTimer();
  }

  /// Bắt đầu timer kiểm tra định kỳ
  void _startCheckTimer() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(
      const Duration(milliseconds: 500), // Kiểm tra mỗi 500ms
      (_) => _checkStability(),
    );
  }

  /// Cập nhật thời gian ổn định
  void updateStabilizationDelay(int delay) {
    _stabilizationDelay = delay;
    reset();
  }

  /// Thêm giá trị trọng lượng mới
  void addWeight(double weight) {
    // Nếu danh sách trống, thêm và thoát
    if (_recentWeights.isEmpty) {
      _recentWeights.add(weight);
      return;
    }

    // Kiểm tra chênh lệch với giá trị gần nhất
    final lastWeight = _recentWeights.last;
    final changeDiff = (weight - lastWeight).abs();

    // Nếu thay đổi quá lớn (>2kg), đó là mã mới → xóa tất cả mẫu cũ
    if (changeDiff > 2.0) {
      if (kDebugMode) {
        print('🔄 Phát hiện mã mới (đổi: $changeDiff kg). Reset mẫu.');
      }
      _recentWeights.clear();
      _wasStable = false;
    }

    _recentWeights.add(weight);

    // Giữ lại chỉ những giá trị trong khoảng thời gian ổn định
    final maxSamples = (_stabilizationDelay * 1000) ~/ 100;
    if (_recentWeights.length > maxSamples) {
      _recentWeights.removeAt(0);
    }
  }

  /// Kiểm tra xem cân có ổn định không (gọi định kỳ)
  void _checkStability() {
    if (_recentWeights.isEmpty) {
      _wasStable = false;
      return;
    }

    // Kiểm tra có đủ mẫu chưa - cần 70% của maxSamples (thay vì 50%)
    final maxSamples = (_stabilizationDelay * 1000) ~/ 100;
    if (_recentWeights.length < maxSamples * 0.7) {
      _wasStable = false;
      return;
    }

    final minWeight = _recentWeights.reduce((a, b) => a < b ? a : b);
    final maxWeight = _recentWeights.reduce((a, b) => a > b ? a : b);
    final diff = maxWeight - minWeight;

    final isStable = diff <= _stabilityThreshold;

    if (kDebugMode) {
      print('📊 Kiểm tra ổn định: diff=$diff kg (ngưỡng=${_stabilityThreshold}kg), mẫu=${_recentWeights.length}/$maxSamples, ổn định=$isStable');
    }

    // Chỉ gọi callback khi chuyển từ không ổn định sang ổn định
    if (isStable && !_wasStable) {
      if (kDebugMode) {
        print('✅ Cân ổn định! (Chênh lệch: $diff kg, Giá trị: ${_recentWeights.last} kg)');
      }
      onStable?.call();
      _wasStable = true;
    } else if (!isStable) {
      _wasStable = false;
    }
  }

  /// Reset trạng thái
  void reset() {
    _recentWeights.clear();
    _wasStable = false;
  }

  /// Hủy service
  void dispose() {
    _checkTimer?.cancel();
    _recentWeights.clear();
  }
}
