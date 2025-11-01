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

  double _activeTotalTargetQty = 0.0;
  double _activeTotalNhap = 0.0;
  double _activeTotalXuat = 0.0;
  // Getters
  double get activeTotalTargetQty => _activeTotalTargetQty;
  double get activeTotalNhap => _activeTotalNhap;
  double get activeTotalXuat => _activeTotalXuat;

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

      _activeTotalTargetQty = (data['totalTargetQty'] as num).toDouble();
      _activeTotalNhap = (data['totalNhapWeighed'] as num).toDouble();
      _activeTotalXuat = (data['totalXuatWeighed'] as num).toDouble();

      _standardWeight = (data['qtys'] as num).toDouble();
      _calculateMinMax();

      final newRecord = WeighingRecord(
        maCode: data['maCode'],
        ovNO: data['ovNO'],
        package: data['package'],
        mUserID: data['mUserID'].toString(),
        qtys: (data['qtys'] as num).toDouble(),
        soLo: data['soLo'],
        tenPhoiKeo: data['tenPhoiKeo'],
        soMay: data['soMay'],
        nguoiThaoTac: data['nguoiThaoTac'],
      );

      _records.insert(0, newRecord);
      if (_records.length > 2) { // số lượng hàng tối đa
        _records.removeLast();
      }
      
      NotificationService().showToast(
        context: context,
       message: 'Scan mã $code thành công!',
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
Future<bool> completeCurrentWeighing(BuildContext context, double currentWeight) async {
    if (_records.isEmpty) {
      return false; // Không có gì để hoàn tất
    }
    final currentRecord = _records[0];

    if (currentRecord.isSuccess == true) {
      return true; // Đã hoàn tất rồi
    }

    // Kiểm tra trọng lượng (vẫn kiểm tra ở client)
    final bool isInRange = (currentWeight >= _minWeight) && (currentWeight <= _maxWeight);

    if (isInRange) {
      final thoiGianCan = DateTime.now();
      final loaiCan = (_selectedWeighingType == WeighingType.nhap) ? 'nhap' : 'xuat';

      // 1. Chuẩn bị dữ liệu gửi đi
      final Map<String, dynamic> body = {
        'maCode': currentRecord.maCode,
        'khoiLuongCan': currentWeight,
        'thoiGianCan': thoiGianCan.toIso8601String(), // Gửi giờ UTC
        'loai': loaiCan,
      };

      try {
        final url = Uri.parse('$_apiBaseUrl/api/complete');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        ).timeout(const Duration(seconds: 10));

        if (!context.mounted) return false;

        // 2. Xử lý kết quả
        if (response.statusCode == 201) {
          final data = json.decode(response.body);
          // THÀNH CÔNG: Cập nhật UI
          NotificationService().showToast(
            context: context,
            message: 'Tên Phôi Keo: ${currentRecord.tenPhoiKeo}\n'
                     'Số Lô: ${currentRecord.soLo}\n'
                     'Đã cân: ${currentWeight.toStringAsFixed(3)} kg!',
            type: ToastType.success,
          );
          currentRecord.isSuccess = true;
          currentRecord.mixTime = thoiGianCan;
          currentRecord.realQty = currentWeight;
          currentRecord.loai = loaiCan;

          //Load lại thông tin cho hàng tổng kết
          final summary = data['summaryData'];
          if (summary != null) {
            _activeTotalTargetQty = (summary['totalTargetQty'] as num).toDouble();
            _activeTotalNhap = (summary['totalNhapWeighed'] as num).toDouble();
            _activeTotalXuat = (summary['totalXuatWeighed'] as num).toDouble();
            _activeMemo = summary['memo']; // Memo cũng được cập nhật
          }

          _standardWeight = 0.0;
          _calculateMinMax();
          notifyListeners();
          return true; // Báo thành công
        } else {
          // LỖI SERVER:
          final errorData = json.decode(response.body);
          NotificationService().showToast(
            context: context,
            message: 'Lỗi server: ${errorData['message'] ?? response.statusCode}',
            type: ToastType.error,
          );
          return false;
        }

      } catch (e) {
        // LỖI MẠNG
        if (!context.mounted) return false;
        NotificationService().showToast(
          context: context,
          message: 'Lỗi mạng: Không thể lưu kết quả.',
          type: ToastType.error,
        );
        return false;
      }
      
    } else {
      // KHÔNG ĐẠT (Lỗi do client, không gọi API)
      NotificationService().showToast(
        context: context,
        message: 'Lỗi: Trọng lượng không nằm trong phạm vi!',
        type: ToastType.error,
      );
      return false;
    }
  }
}