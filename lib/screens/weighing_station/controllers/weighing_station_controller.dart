import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../../data/weighing_data.dart';
import '../../../services/bluetooth_service.dart';
import '../../../services/notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum WeighingType { nhap, xuat }

class WeighingStationController with ChangeNotifier {
  final BluetoothService bluetoothService;

  // --- ĐỊNH NGHĨA IP CỦA BACKEND ---
  // (Dùng 10.0.2.2 nếu chạy trên Android Emulator)
  // (Dùng IP Mạng LAN của máy tính nếu chạy trên điện thoại thật, vd: 'http://192.168.1.10:3636')
  final String _apiBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3636';

  String? _activeOVNO;
  String? _activeMemo;
  String? get activeOVNO => _activeOVNO;
  String? get activeMemo => _activeMemo;

  // --- State ---
  final List<WeighingRecord> _records = [];
  List<WeighingRecord> get records => _records;

  double _selectedPercentage = 1.0;
  double get selectedPercentage => _selectedPercentage;
  double _standardWeight = 0.0;
  double get khoiLuongMe => _standardWeight;
  double _minWeight = 0.0;
  double _maxWeight = 0.0;
  double get minWeight => _minWeight;
  double get maxWeight => _maxWeight;
  WeighingType _selectedWeighingType = WeighingType.nhap;
  WeighingType get selectedWeighingType => _selectedWeighingType;

  // --- HẾT PHẦN STATE ---

  WeighingStationController({required this.bluetoothService});

  // (Hàm _calculateMinMax, updatePercentage, updateWeighingType giữ nguyên)
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

  // --- Hàm cập nhật % ---
  void updatePercentage(double newPercentage) {
    _selectedPercentage = newPercentage;
    _calculateMinMax();
    notifyListeners();
  }
  void updateWeighingType(WeighingType? newType) {
    if (newType != null) {
      _selectedWeighingType = newType;
      // Không cần notifyListeners vì UI chỉ thay đổi khi scan mã mới
    }
  }


  // --- HÀM handleScan ---
  Future<void> handleScan(BuildContext context, String code) async {
  try {
    final url = Uri.parse('$_apiBaseUrl/api/scan/$code');
    
    // Log để debug
    if (kDebugMode) {
      print('🔍 Attempting to connect to: $url');
    }
    
    final response = await http.get(url).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Connection timeout after 10 seconds');
      },
    );
    
    if (kDebugMode) {
      print('📡 Response Status: ${response.statusCode}');
    }
    if (kDebugMode) {
      print('📦 Response Body: ${response.body}');
    }
    
    if (!context.mounted) return;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (_activeOVNO == null || _activeOVNO != data['ovNO']) {
        _activeOVNO = data['ovNO'];
        _activeMemo = data['memo'];
      }

      _standardWeight = (data['qtys'] as num).toDouble();
      _calculateMinMax();

      final newRecord = WeighingRecord(
        maCode: data['maCode'],
        ovNO: data['ovNO'],
        package: data['package'],
        mUserID: data['mUserID'],
        qtys: (data['qtys'] as num).toDouble(),
        soLo: data['soLo'],
        tenPhoiKeo: data['tenPhoiKeo'],
        soMay: data['soMay'],
        nguoiThaoTac: data['nguoiThaoTac'],
      );

      _records.insert(0, newRecord);
      if (_records.length > 5) {
        _records.removeLast();
      }
      
      NotificationService().showToast(
        context: context,
        message: 'Scan thành công!',
        type: ToastType.success,
      );
    
    } else if (response.statusCode == 404) {
      final errorData = json.decode(response.body);
      NotificationService().showToast(
        context: context,
        message: errorData['message'] ?? 'Không tìm thấy mã',
        type: ToastType.error,
      );
    } else {
      NotificationService().showToast(
        context: context,
        message: 'Lỗi server: ${response.statusCode}',
        type: ToastType.error,
      );
    }

  } on TimeoutException catch (e) {
    if (kDebugMode) {
      print('⏱️ Timeout: $e');
    }
    if (!context.mounted) return;
    NotificationService().showToast(
      context: context,
      message: 'Lỗi: Hết thời gian chờ kết nối!',
      type: ToastType.error,
    );
  } on http.ClientException catch (e) {
    if (kDebugMode) {
      print('🌐 Client Exception: $e');
    }
    if (!context.mounted) return;
    NotificationService().showToast(
      context: context,
      message: 'Lỗi kết nối: Kiểm tra WiFi và địa chỉ IP server.',
      type: ToastType.error,
    );
  } on SocketException catch (e) {
    if (kDebugMode) {
      print('🔌 Socket Exception: $e');
    }
    if (!context.mounted) return;
    NotificationService().showToast(
      context: context,
      message: 'Không thể kết nối: Đảm bảo điện thoại và máy tính cùng mạng WiFi.',
      type: ToastType.error,
    );
  } catch (e) {
    if (kDebugMode) {
      print('❌ Unknown Error: $e');
    }
    if (!context.mounted) return;
    NotificationService().showToast(
      context: context,
      message: 'Lỗi không xác định: $e',
      type: ToastType.error,
    );
  } finally {
    notifyListeners();
  }
}
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
}