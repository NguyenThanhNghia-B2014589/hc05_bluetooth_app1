import 'package:flutter/material.dart';
import '../../../data/weighing_data.dart';
import '../../../services/bluetooth_service.dart';
import '../../../services/notification_service.dart';

// Lớp này sẽ là "bộ não" quản lý logic và trạng thái cho WeighingStationScreen
class WeighingStationController with ChangeNotifier {
  final BluetoothService bluetoothService;
  
  // Dữ liệu mẫu được quản lý bên trong controller
  final Map<String, Map<String, dynamic>> _mockData = mockWeighingData;

  // Danh sách các bản ghi, được quản lý bởi controller
  final List<WeighingRecord> _records = [];
  List<WeighingRecord> get records => _records; // Cung cấp getter để UI có thể đọc

  double _selectedPercentage = 0.3; // Mặc định là 0.3%
  double _standardWeight = 0.0;
  double _minWeight = 0.0;
  double _maxWeight = 0.0;

  // Cung cấp getters để UI có thể đọc
  double get selectedPercentage => _selectedPercentage;
  double get minWeight => _minWeight;
  double get maxWeight => _maxWeight;
  double get khoiLuongMe => _standardWeight;

  WeighingStationController({required this.bluetoothService});

  // --- HÀM TÍNH TOÁN MIN/MAX ---
  void _calculateMinMax() {
    if (_standardWeight == 0) {
      _minWeight = 0.0;
      _maxWeight = 0.0;
    } else {
      final deviation = _standardWeight * (_selectedPercentage / 100.0);
      _minWeight = _standardWeight - deviation;
      _maxWeight = _standardWeight + deviation;
    }
  }

  // --- HÀM CẬP NHẬT KHI THAY ĐỔI DROPDOWN ---
  void updatePercentage(double newPercentage) {
    _selectedPercentage = newPercentage;
    _calculateMinMax(); // Tính toán lại với % mới
    notifyListeners(); // Cập nhật UI
  }

  // --- TOÀN BỘ LOGIC XỬ LÝ SCAN ĐƯỢC CHUYỂN VÀO ĐÂY ---
  void handleScan(BuildContext context, String code) {
    final data = _mockData[code];

    if (data == null) {
      NotificationService().showToast(
        context: context,
        message: 'Mã "$code" không hợp lệ!',
        type: ToastType.error,
      );
      return;
    }

    NotificationService().showToast(
      context: context,
      message: 'Scan thành công!',
      type: ToastType.success,
    );

    // Lấy khối lượng mẻ từ data và tính toán MIN/MAX
    _standardWeight = data['khoiLuongMe']!;
    _calculateMinMax();

    final newRecord = WeighingRecord(
      tenPhoiKeo: data['tenPhoiKeo']!,
      soLo: data['soLo']!,
      soMay: data['soMay']!,
      khoiLuongMe: data['khoiLuongMe']!, 
      nguoiThaoTac: data['nguoiThaoTac']!,
      thoiGianCan: DateTime.now(), 
    );
    
    _records.insert(0, newRecord);

    if (_records.length > 5) { // Giới hạn chỉ giữ 5 bản ghi gần nhất
      _records.removeLast(); // Xóa mục cũ nhất (ở cuối danh sách)
    }
    
    // Báo cho bất kỳ widget nào đang lắng nghe rằng dữ liệu đã thay đổi
    notifyListeners();
  }
  
  // Xử lý logic khi nhấn nút "Hoàn tất".
  // Trả về true nếu thành công, false nếu thất bại.
  bool completeCurrentWeighing(double currentWeight) {
    // 1. Kiểm tra xem có bản ghi nào để "hoàn tất" không
    if (_records.isEmpty) {
      return false; // Không có gì để hoàn tất
    }

    // 2. Kiểm tra xem bản ghi mới nhất đã hoàn tất chưa
    if (_records[0].isSuccess == true) {
      return true; // Đã hoàn tất thành công rồi
    }

    // 3. Kiểm tra trọng lượng có nằm trong phạm vi cho phép không
    final bool isInRange = (currentWeight >= _minWeight) && (currentWeight <= _maxWeight);

    if (isInRange) {
      // 4. Nếu ĐẠT: Cập nhật bản ghi và báo cho UI
      _records[0].isSuccess = true;
      notifyListeners(); // Báo cho WeighingTable cập nhật màu
      return true;
    } else {
      // 5. Nếu KHÔNG ĐẠT: Không làm gì cả, trả về false
      return false;
    }
  }
}