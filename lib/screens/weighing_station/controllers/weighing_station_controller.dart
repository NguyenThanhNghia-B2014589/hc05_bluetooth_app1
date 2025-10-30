import 'package:flutter/material.dart';
import '../../../data/weighing_data.dart'; // Import data mới
import '../../../services/bluetooth_service.dart';
import '../../../services/notification_service.dart';

// Enum WeighingType vẫn giữ nguyên
enum WeighingType { nhap, xuat }

class WeighingStationController with ChangeNotifier {
  final BluetoothService bluetoothService;
  
String? _activeOVNO; // To store the OVNO of the current scan group
String? _activeMemo; // To store the Memo for the active OVNO
String? get activeOVNO => _activeOVNO; // Getter for UI
String? get activeMemo => _activeMemo; // Getter for UI


  // --- Dữ liệu Mock (giờ lấy từ weighing_data.dart) ---
  final Map<String, Map<String, dynamic>> _workLSData = mockWorkLSData;
  final Map<String, Map<String, dynamic>> _workData = mockWorkData;
  final Map<int, Map<String, dynamic>> _persionalData = mockPersionalData;

  // --- State ---
  final List<WeighingRecord> _records = []; // Danh sách hiển thị trên bảng
  List<WeighingRecord> get records => _records;

  double _selectedPercentage = 1.0;
  double get selectedPercentage => _selectedPercentage;

  // _standardWeight giờ là Qty (Khối lượng mẻ/tồn)
  double _standardWeight = 0.0;
  double get khoiLuongMe => _standardWeight; // Giữ getter cũ cho UI

  double _minWeight = 0.0;
  double _maxWeight = 0.0;
  double get minWeight => _minWeight;
  double get maxWeight => _maxWeight;

  WeighingType _selectedWeighingType = WeighingType.nhap;
  WeighingType get selectedWeighingType => _selectedWeighingType;

  WeighingStationController({required this.bluetoothService});

  // --- Hàm tính Min/Max (giữ nguyên) ---
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

  // --- Hàm cập nhật % (giữ nguyên) ---
  void updatePercentage(double newPercentage) {
    _selectedPercentage = newPercentage;
    _calculateMinMax();
    notifyListeners();
  }

  // --- Hàm cập nhật Loại cân (giữ nguyên) ---
  void updateWeighingType(WeighingType? newType) {
    if (newType != null) {
      _selectedWeighingType = newType;
      // Không cần notifyListeners vì UI chỉ thay đổi khi scan mã mới
    }
  }

  // --- THAY THẾ TOÀN BỘ HÀM handleScan ---
  void handleScan(BuildContext context, String code) {
    // 1. Tìm bản ghi trong _VML_WorkLS
    final workLSItem = _workLSData[code];

    if (workLSItem == null) {
      NotificationService().showToast(
        context: context,
        message: 'Mã "$code" không hợp lệ!',
        type: ToastType.error,
      );
      return;
    }

    // 2. Lấy thông tin từ _VML_WorkLS
    final String ovNO = workLSItem['OVNO'];
    final int package = workLSItem['package'];
    final int mUserID = workLSItem['MUserID'];
    final double qtyValue = workLSItem['Qty']; // Đây là khối lượng mẻ/tồn

    // 3. Tìm thông tin trong _VML_Work (dùng ovNO)
    final workItem = _workData[ovNO];
    if (workItem == null) {
       NotificationService().showToast(
        context: context,
        message: 'Lỗi: Không tìm thấy thông tin công việc cho OVNO "$ovNO"!',
        type: ToastType.error,
      );
      return;
    }

    if (_activeOVNO == null || _activeOVNO != ovNO) {
      _activeOVNO = ovNO;
      // Look up Memo from mockWorkData
      final workItem = _workData[ovNO];
      _activeMemo = workItem?['Memo'] as String?;
      // No need to notifyListeners here, it happens later
    }

    final String tenPhoiKeo = workItem['FormulaF'];
    final String soMay = workItem['soMay'];

    // 4. Tìm thông tin trong _VML_Persional (dùng mUserID)
    final persionalItem = _persionalData[mUserID];
    final String nguoiThaoTac = persionalItem?['UerName'] ?? 'Không rõ';

    // 5. Cập nhật _standardWeight và tính Min/Max
    // Nếu là Cân Xuất, Qty lấy từ WorkLS chính là khối lượng tồn
    // Nếu là Cân Nhập, Qty lấy từ WorkLS cũng là khối lượng mẻ cần cân
    _standardWeight = qtyValue;
    _calculateMinMax();

    // 6. Tạo bản ghi mới (chưa có thời gian và khối lượng cân)
    final newRecord = WeighingRecord(
      maCode: code,
      ovNO: ovNO,
      package: package,
      mUserID: mUserID,
      qty: _standardWeight, // Lưu khối lượng mẻ/tồn
      // Bổ sung thông tin đã tra cứu
      tenPhoiKeo: tenPhoiKeo,
      soMay: soMay,
      nguoiThaoTac: nguoiThaoTac,
      soLo: package,
      // isSuccess và realQty sẽ được cập nhật khi hoàn tất
      // loai sẽ được xác định khi hoàn tất
    );

    // 7. Thêm vào danh sách hiển thị và giới hạn 5 hàng
    _records.insert(0, newRecord);
    if (_records.length > 2) {
      _records.removeLast();
    }

    notifyListeners(); // Cập nhật bảng

    NotificationService().showToast(
      context: context,
      message: 'Scan thành công!',
      type: ToastType.success,
    );
  }
  // --- KẾT THÚC THAY THẾ ---

  // --- THAY THẾ TOÀN BỘ HÀM completeCurrentWeighing ---
  bool completeCurrentWeighing(double currentWeight) {
    if (_records.isEmpty) {
      return false; // Không có gì để hoàn tất
    }
    // Lấy bản ghi đang chờ (bản ghi đầu tiên)
    final currentRecord = _records[0];

    // Kiểm tra xem đã hoàn tất chưa
    if (currentRecord.isSuccess == true) {
      return true; // Đã hoàn tất rồi
    }

    // Kiểm tra trọng lượng
    final bool isInRange = (currentWeight >= _minWeight) && (currentWeight <= _maxWeight);

    if (isInRange) {
      // Cập nhật bản ghi
      currentRecord.isSuccess = true;
      currentRecord.mixTime = DateTime.now(); // Lưu thời gian hoàn tất
      currentRecord.realQty = currentWeight; // Lưu khối lượng cân thực tế
      currentRecord.loai = (_selectedWeighingType == WeighingType.nhap) ? 'nhap' : 'xuat'; // Lưu loại

      // TODO: Ở đây bạn cần có logic để LƯU bản ghi này vào database
      // Ví dụ: await databaseService.saveRecord(currentRecord);
      // Hoặc cập nhật lại mockWorkLSData nếu chỉ dùng mock

      // After successfully completing, clear the active group info
      // _activeOVNO = null;
      // _activeMemo = null;
      // (Commented out for now, keep showing summary until next scan)

      // Reset state
      _standardWeight = 0.0;
      _calculateMinMax();
      notifyListeners(); // Cập nhật UI (bảng đổi màu xanh, nút hoàn tất reset)
      return true;
    } else {
      // Không đạt
      return false;
    }
  }
  // --- KẾT THÚC THAY THẾ ---
}