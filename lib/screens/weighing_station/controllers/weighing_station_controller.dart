import 'package:flutter/material.dart';
import '../../../data/weighing_data.dart';
import '../../../services/bluetooth_service.dart';
import '../../../services/notification_service.dart';

enum WeighingType { nhap, xuat }

// Lớp này sẽ là "bộ não" quản lý logic và trạng thái cho WeighingStationScreen
class WeighingStationController with ChangeNotifier {
  final BluetoothService bluetoothService;
  
  // Dữ liệu mẫu được quản lý bên trong controller
  final Map<String, Map<String, dynamic>> _mockData = mockWeighingData;
  final Map<String, Map<String, dynamic>> _mockStockData = mockLastWeighingData;

  // Danh sách các bản ghi, được quản lý bởi controller
  final List<WeighingRecord> _records = [];
  List<WeighingRecord> get records => _records; // Cung cấp getter để UI có thể đọc

  double _selectedPercentage = 1; // Mặc định là 1%
  double _standardWeight = 0.0;
  double _minWeight = 0.0;
  double _maxWeight = 0.0;

  // Cung cấp getters để UI có thể đọc
  double get selectedPercentage => _selectedPercentage;
  double get minWeight => _minWeight;
  double get maxWeight => _maxWeight;
  double get khoiLuongMe => _standardWeight;

  WeighingStationController({required this.bluetoothService});

  WeighingType _selectedWeighingType = WeighingType.nhap; // Mặc định là Cân nhập
  WeighingType get selectedWeighingType => _selectedWeighingType;

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

  // --- HÀM CẬP NHẬT KHI THAY ĐỔI LOẠI CÂN ---
  void updateWeighingType(WeighingType? newType) {
    if (newType != null) {
      _selectedWeighingType = newType;
      notifyListeners(); // Cập nhật UI
    }
  }

  // --- TOÀN BỘ LOGIC XỬ LÝ SCAN ĐƯỢC CHUYỂN VÀO ĐÂY ---
  void handleScan(BuildContext context, String code) {
    // 1. Quyết định xem nên lấy data từ đâu
    Map<String, dynamic>? data;
    double? standardWeightValue; // Khối lượng mẻ (nhập) hoặc tồn (xuất)

    if (_selectedWeighingType == WeighingType.nhap) {
      // CÂN NHẬP: Lấy data từ mockData (target)
      data = _mockData[code];
      if (data != null) {
        standardWeightValue = data['khoiLuongMe'];
      }
    } else {
      // CÂN XUẤT: Lấy data từ mockStockData (tồn kho)
      // (Giả sử 2 mock data dùng chung key '123', '456'...)
      data = _mockStockData[code]; 
      
      if (data != null) {
        // Lấy khối lượng tồn (khoiLuongSauCan) làm khối lượng tiêu chuẩn
        //standardWeightValue = data['khoiLuongSauCan']; // Tạm thời chưa dùng
        standardWeightValue = data['khoiLuongMe'];
      }
    }

    // 2. Kiểm tra data
    if (data == null || standardWeightValue == null) {
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

    // 3. Gán khối lượng mẻ/tồn
    _standardWeight = standardWeightValue;
    _calculateMinMax(); // Tính min/max dựa trên khối lượng này

    // 4. Tạo record
    final newRecord = WeighingRecord(
      maCode: code,
      tenPhoiKeo: data['tenPhoiKeo']!,
      soLo: data['soLo']!,
      soMay: data['soMay']!,
      khoiLuongMe: _standardWeight, // Gán _standardWeight (đã được xử lý)
      nguoiThaoTac: data['nguoiThaoTac']!,
    );
    
    _records.insert(0, newRecord);
    if (_records.length > 4) {
      _records.removeLast();
    }
    
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
      // Nếu ĐẠT: Cập nhật bản ghi
      _records[0].isSuccess = true;
      // Gán thời gian khi hoàn tất cân
      _records[0].thoiGianCan = DateTime.now();
      // Gán khối lượng đã cân
      _records[0].khoiLuongDaCan = currentWeight;
      // 5. Reset khối lượng mẻ về 0
      _standardWeight = 0.0;
      // 6. Tính toán lại min/max (sẽ về 0)
      _calculateMinMax();
      // 7. Báo cho TOÀN BỘ UI cập nhật
      notifyListeners(); 
      return true;
    } else {
      // 8. Nếu KHÔNG ĐẠT: Không làm gì cả, trả về false
      return false;
    }
  }
}