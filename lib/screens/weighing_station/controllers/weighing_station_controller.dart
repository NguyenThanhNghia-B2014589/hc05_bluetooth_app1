import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../../services/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import '../../../data/weighing_data.dart';
import '../../../services/bluetooth_service.dart';
import '../../../services/notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../services/sync_service.dart';
import '../../../services/server_status_service.dart';


enum WeighingType { nhap, xuat }

class WeighingException implements Exception {
  final String message;
  WeighingException(this.message);
}

class WeighingStationController with ChangeNotifier {
  final BluetoothService bluetoothService;

  // --- ĐỊNH NGHĨA IP CỦA BACKEND ---
  // (Dùng 10.0.2.2 nếu chạy trên Android Emulator)
  // (Dùng IP Mạng LAN của máy tính nếu chạy trên điện thoại thật, vd: 'http://192.168.1.10:3636')
  final String _apiBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3636';

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SyncService _syncService = SyncService();
  final ServerStatusService _serverStatus = ServerStatusService();

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
  int _activeXWeighed = 0; // Số mẻ đã cân (X)
  int _activeYTotal = 0;   // Tổng số mẻ (Y)
  int get activeXWeighed => _activeXWeighed;
  int get activeYTotal => _activeYTotal;

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

  Future<Map<String, dynamic>> _scanFromCache(Database db, String code) async {
    final List<Map<String, dynamic>> localData = await db.rawQuery(
      '''
      SELECT S.maCode, S.ovNO, S.package, S.mUserID, S.qtys,
             W.tenPhoiKeo, W.soMay, W.memo, W.totalTargetQty,
             P.nguoiThaoTac, S.package as soLo
      FROM VmlWorkS AS S
      LEFT JOIN VmlWork AS W ON S.ovNO = W.ovNO
      LEFT JOIN VmlPersion AS P ON S.mUserID = P.mUserID
      WHERE S.maCode = ?
      ''', [code]
    );

    if (localData.isNotEmpty) {
      if (kDebugMode) {
        print('🔍 Tìm thấy mã $code trong cache cục bộ.');
      }
      return localData.first;
    } else {
      // Nếu không tìm thấy trong cache
      throw WeighingException('Mã "$code" không có trong dữ liệu offline.');
    }
  }
  
  // --- HÀM handleScan ---
  Future<void> handleScan(BuildContext context, String code) async {
    Map<String, dynamic> data; // Biến để lưu kết quả cuối cùng
    final db = await _dbHelper.database;

    // Kiểm tra trạng thái server (từ service đã chạy nền)
    final bool isServerConnected = _serverStatus.isServerConnected;

    try {
      if (isServerConnected) {
        // --- 1. CHẾ ĐỘ ONLINE (Ưu tiên API) ---
        if (kDebugMode) {
          print('🛰️ Online Mode: Đang gọi API...');
        }
        try {
          final url = Uri.parse('$_apiBaseUrl/api/scan/$code');
          final response = await http.get(url).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            data = json.decode(response.body);
            if (kDebugMode) {
              print('🛰️ API thành công, đang cache dữ liệu...');
            }

            // Cập nhật (hoặc thêm mới) cache
            await db.insert('VmlWorkS', {
              'maCode': data['maCode'], 'ovNO': data['ovNO'], 'package': data['package'],
              'mUserID': data['mUserID'].toString(), 'qtys': data['qtys'],
            }, conflictAlgorithm: ConflictAlgorithm.replace);

            await db.insert('VmlWork', {
              'ovNO': data['ovNO'], 'tenPhoiKeo': data['tenPhoiKeo'], 'soMay': data['soMay'],
              'memo': data['memo'], 'totalTargetQty': data['totalTargetQty'],
            }, conflictAlgorithm: ConflictAlgorithm.replace);

            await db.insert('VmlPersion', {
              'mUserID': data['mUserID'].toString(), 'nguoiThaoTac': data['nguoiThaoTac'],
            }, conflictAlgorithm: ConflictAlgorithm.replace);

          } else if (response.statusCode == 404) {
            final errorData = json.decode(response.body);
            throw WeighingException(errorData['message'] ?? 'Không tìm thấy mã');
          } else {
            throw WeighingException('Lỗi server: ${response.statusCode}, thử lại offline...');
          }

        } catch (e) {
          // LỖI API (Timeout, 500...): Chuyển sang tìm trong cache (Fallback)
          if (kDebugMode) {
            print('⚠️ Lỗi API ($e). Đang thử tìm trong cache cục bộ...');
          }
          data = await _scanFromCache(db, code);
        }
      } else {
        // --- 2. CHẾ ĐỘ OFFLINE (Chỉ dùng Cache) ---
        if (kDebugMode) {
          print('🔌 Offline Mode: Đang tìm trong cache cục bộ...');
        }
        data = await _scanFromCache(db, code);
      }

      // --- 3. CẬP NHẬT UI (CHUNG) ---
      // (Code này chạy dù lấy từ API hay Cache)
      if (!context.mounted) return;

      if (_activeOVNO == null || _activeOVNO != data['ovNO']) {
        _activeOVNO = data['ovNO'];
        _activeMemo = data['memo'];
      }
      _activeTotalTargetQty = (data['totalTargetQty'] as num? ?? 0.0).toDouble();
      // (totalNhap/Xuat sẽ được cập nhật khi API Scan trả về,
      // chúng ta cần đảm bảo localData cũng trả về giá trị này nếu có)
      _activeTotalNhap = (data['totalNhapWeighed'] as num? ?? 0.0).toDouble();
      _activeTotalXuat = (data['totalXuatWeighed'] as num? ?? 0.0).toDouble();
      _activeXWeighed = (data['x_WeighedNhap'] as num? ?? 0).toInt();
      _activeYTotal = (data['y_TotalPackages'] as num? ?? 0).toInt();
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
        soMay: data['soMay'].toString(),
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

    } on WeighingException catch (e) { // Bắt lỗi (vd: "Không có trong cache")
      if (kDebugMode) print('⚖️ Lỗi nghiệp vụ: ${e.message}');
      if (!context.mounted) return;
      NotificationService().showToast(
        context: context, message: e.message, type: ToastType.error,
      );
    } catch (e) {
      if (kDebugMode) print('❌ Lỗi không xác định: $e');
      if (!context.mounted) return;
      NotificationService().showToast(
        context: context, message: 'Lỗi không xác định: $e', type: ToastType.error,
      );
    } finally {
      notifyListeners();
    }
  }

  Future<bool> completeCurrentWeighing(BuildContext context, double currentWeight) async {
    if (_records.isEmpty) {
      NotificationService().showToast(
        context: context, message: 'Vui lòng scan mã trước.', type: ToastType.error,
      );
      return false;
    }
    final currentRecord = _records[0];

    if (currentRecord.isSuccess == true) {
      return true; // Đã hoàn tất rồi
    }

    final bool isInRange = (currentWeight >= _minWeight) && (currentWeight <= _maxWeight);

    if (!isInRange) {
      // Lỗi không nằm trong phạm vi (Báo lỗi ngay)
      NotificationService().showToast(
        context: context,
        message: 'Lỗi: Trọng lượng không nằm trong phạm vi!',
        type: ToastType.error,
      );
      return false;
    }

    // Nếu đã nằm trong phạm vi, bắt đầu xử lý DB
    final thoiGianCan = DateTime.now();
    final loaiCan = (_selectedWeighingType == WeighingType.nhap) ? 'nhap' : 'xuat';

    final Map<String, dynamic> localData = {
      'maCode': currentRecord.maCode,
      'khoiLuongCan': currentWeight,
      'thoiGianCan': thoiGianCan.toIso8601String(),
      'loai': loaiCan,
    };

    try {
      final db = await _dbHelper.database;

      // KIỂM TRA OFFLINE
      if (loaiCan == 'nhap') {
        final List<Map<String, dynamic>> existingInQueue = await db.query(
          'HistoryQueue',
          where: 'maCode = ? AND loai = ?',
          whereArgs: [currentRecord.maCode, 'nhap'],
        );

        if (existingInQueue.isNotEmpty) {
          // NÉM LỖI NGHIỆP VỤ
          throw WeighingException('Mã này đã được cân (đang chờ đồng bộ).');
        }
      }

      // LƯU VÀO HÀNG ĐỢI
      await db.insert('HistoryQueue', localData);

      // CẬP NHẬT UI
      currentRecord.isSuccess = true;
      currentRecord.mixTime = thoiGianCan;
      currentRecord.realQty = currentWeight;
      currentRecord.loai = loaiCan;
      _standardWeight = 0.0;
      _calculateMinMax();

      // HIỂN THỊ THÔNG BÁO THÀNH CÔNG
      if (!context.mounted) return false;
      NotificationService().showToast(
        context: context,
        message: 'Tên Phôi Keo: ${currentRecord.tenPhoiKeo}\n'
                'Số Lô: ${currentRecord.soLo}\n'
                'Đã cân: ${currentWeight.toStringAsFixed(3)} kg!',
        type: ToastType.success,
      );

      // THỬ ĐỒNG BỘ (NGẦM)
      _syncService.syncHistoryQueue(); 

      notifyListeners();
      return true;

    } on WeighingException catch (e) {
      // --- BẮT LỖI NGHIỆP VỤ (MỚI) ---
      if (kDebugMode) print('⚖️ Lỗi nghiệp vụ cân: ${e.message}');
      if (!context.mounted) return false;
      NotificationService().showToast(
        context: context,
        message: e.message, // Hiển thị đúng lỗi "Mã này đã được cân..."
        type: ToastType.error,
      );
      return false;

    } catch (e) {
      // --- BẮT LỖI NGHIÊM TRỌNG ---
      if (kDebugMode) print('❌ Lỗi lưu SQLite: $e');
      if (!context.mounted) return false;
      NotificationService().showToast(
        context: context,
        message: 'Lỗi nghiêm trọng: Không thể lưu vào DB cục bộ.',
        type: ToastType.error,
      );
      return false;
    }
  }

}