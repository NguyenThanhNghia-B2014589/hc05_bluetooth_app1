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
  final String _apiBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3636';

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SyncService _syncService = SyncService();
  final ServerStatusService _serverStatus = ServerStatusService();

  String? _activeOVNO;
  String? _activeMemo;
  String? get activeOVNO => _activeOVNO;
  String? get activeMemo => _activeMemo;

  // --- STATE ---
  final List<WeighingRecord> _records = [];
  List<WeighingRecord> get records => _records;

  double _activeTotalTargetQty = 0.0;
  double _activeTotalNhap = 0.0;
  double _activeTotalXuat = 0.0;
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
  int _activeXWeighed = 0;
  int _activeYTotal = 0;
  int get activeXWeighed => _activeXWeighed;
  int get activeYTotal => _activeYTotal;

  WeighingType _selectedWeighingType = WeighingType.nhap;
  WeighingType get selectedWeighingType => _selectedWeighingType;

  WeighingStationController({required this.bluetoothService});

  // --- HÀM TÍNH TOÁN ---
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

  void updatePercentage(double newPercentage) {
    _selectedPercentage = newPercentage;
    _calculateMinMax();
    notifyListeners();
  }

  void updateWeighingType(WeighingType? newType) {
    if (newType != null) {
      _selectedWeighingType = newType;
    }
  }

  // --- LẤY DỮ LIỆU OFFLINE ---
  Future<Map<String, dynamic>> _scanFromCache(Database db, String code) async {
  final List<Map<String, dynamic>> localData = await db.rawQuery(
    '''
    SELECT S.maCode, S.ovNO, S.package, S.mUserID, S.qtys,
           S.loai,
           W.tenPhoiKeo, W.soMay, W.memo, W.totalTargetQty,
           P.nguoiThaoTac, S.package as soLo
    FROM VmlWorkS AS S
    LEFT JOIN VmlWork AS W ON S.ovNO = W.ovNO
    LEFT JOIN VmlPersion AS P ON S.mUserID = P.mUserID
    WHERE S.maCode = ?
    ''',
    [code],
  );

  if (localData.isNotEmpty) {
    if (kDebugMode) {
      print('🔍 Tìm thấy mã $code trong cache cục bộ.');
    }
    return localData.first;
  } else {
    throw WeighingException('Mã "$code" không có trong dữ liệu offline.');
  }
}

  // --- HÀM XỬ LÝ SCAN ---
  Future<void> handleScan(BuildContext context, String code) async {
  Map<String, dynamic> data;
  final db = await _dbHelper.database;
  final loaiCan = _selectedWeighingType;
  final bool isServerConnected = _serverStatus.isServerConnected;

  try {
    if (isServerConnected) {
      // --- ONLINE ---
      if (kDebugMode) print('🛰️ Online Mode: Đang gọi API...');
      final url = Uri.parse('$_apiBaseUrl/api/scan/$code');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        data = json.decode(response.body);

        if (loaiCan == WeighingType.nhap && data['isNhapWeighed'] == true) {
          throw WeighingException('Mã này đã được CÂN NHẬP (trên server).');
        }
        if (loaiCan == WeighingType.xuat && data['isXuatWeighed'] == true) {
          throw WeighingException('Mã này đã được CÂN XUẤT (trên server).');
        }

        // Lưu cache
        await db.insert(
          'VmlWork',
          {
            'ovNO': data['ovNO'],
            'tenPhoiKeo': data['tenPhoiKeo'],
            'soMay': data['soMay'],
            'memo': data['memo'],
            'totalTargetQty': data['totalTargetQty'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await db.insert(
          'VmlPersion',
          {
            'mUserID': data['mUserID'].toString(),
            'nguoiThaoTac': data['nguoiThaoTac'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else if (response.statusCode == 404) {
        final errorData = json.decode(response.body);
        throw WeighingException(errorData['message'] ?? 'Không tìm thấy mã');
      } else {
        throw WeighingException('Lỗi server: ${response.statusCode}, thử lại offline...');
      }
    } else {
      // --- OFFLINE ---
      if (kDebugMode) print('🔌 Offline Mode: Đang tìm trong cache cục bộ...');
      data = await _scanFromCache(db, code);

      final loaiOffline = data['loai'];

      if (loaiCan == WeighingType.nhap) {
        // ✅ Nếu cân nhập mà mã đã nhập => báo lỗi
        if (loaiOffline == 'nhap') {
          throw WeighingException('Mã này đã được CÂN NHẬP (lưu trong cache).');
        }
      }

      if (loaiCan == WeighingType.xuat) {
        // ✅ Nếu cân xuất mà mã đã xuất => báo lỗi
        if (loaiOffline == 'xuat') {
          throw WeighingException('Mã này đã được CÂN XUẤT (lưu trong cache).');
        }
        // ✅ Còn nếu loai = 'nhap' hoặc null => cho phép cân xuất
      }
    }

    // --- CẬP NHẬT UI ---
    if (!context.mounted) return;

    if (_activeOVNO == null || _activeOVNO != data['ovNO']) {
      _activeOVNO = data['ovNO'];
      _activeMemo = data['memo'];
    }

    _activeTotalTargetQty = (data['totalTargetQty'] as num? ?? 0.0).toDouble();
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
    if (_records.length > 2) _records.removeLast();

    NotificationService().showToast(
      context: context,
      message: 'Scan mã $code thành công!',
      type: ToastType.success,
    );
  } on WeighingException catch (e) {
    if (kDebugMode) print('⚖️ Lỗi nghiệp vụ: ${e.message}');
    if (!context.mounted) return;
    NotificationService().showToast(context: context, message: e.message, type: ToastType.error);
  } catch (e) {
    if (kDebugMode) print('❌ Lỗi không xác định: $e');
    if (!context.mounted) return;
    NotificationService().showToast(context: context, message: 'Lỗi: $e', type: ToastType.error);
  } finally {
    notifyListeners();
  }
}

  // --- HOÀN TẤT CÂN ---
  Future<bool> completeCurrentWeighing(BuildContext context, double currentWeight) async {
    if (_records.isEmpty) {
      NotificationService().showToast(
        context: context,
        message: 'Vui lòng scan mã trước.',
        type: ToastType.error,
      );
      return false;
    }

    final currentRecord = _records[0];
    if (currentRecord.isSuccess == true) return true;

    final bool isInRange = (currentWeight >= _minWeight) && (currentWeight <= _maxWeight);
    if (!isInRange) {
      NotificationService().showToast(
        context: context,
        message: 'Lỗi: Trọng lượng không nằm trong phạm vi!',
        type: ToastType.error,
      );
      return false;
    }

    final thoiGianCan = DateTime.now();
    final loaiCan = (_selectedWeighingType == WeighingType.nhap) ? 'nhap' : 'xuat';
    final thoiGianString = thoiGianCan.toIso8601String();

    try {
      final db = await _dbHelper.database;

      if (loaiCan == 'nhap') {
        final existingInQueue = await db.query(
          'HistoryQueue',
          where: 'maCode = ? AND loai = ?',
          whereArgs: [currentRecord.maCode, 'nhap'],
        );
        if (existingInQueue.isNotEmpty) {
          throw WeighingException('Mã này đã được cân (đang chờ đồng bộ).');
        }

        final existingInCache = await db.query(
          'VmlWorkS',
          where: 'maCode = ? AND realQty IS NOT NULL',
          whereArgs: [currentRecord.maCode],
        );
        if (existingInCache.isNotEmpty) {
          throw WeighingException('Mã này đã được cân (đã đồng bộ).');
        }
      }

      await db.transaction((txn) async {
        await txn.insert('HistoryQueue', {
          'maCode': currentRecord.maCode,
          'khoiLuongCan': currentWeight,
          'thoiGianCan': thoiGianString,
          'loai': loaiCan,
        });

        await txn.update(
          'VmlWorkS',
          {
            'realQty': currentWeight,
            'mixTime': thoiGianString,
            'loai': loaiCan,
          },
          where: 'maCode = ?',
          whereArgs: [currentRecord.maCode],
        );
      });

      currentRecord.isSuccess = true;
      currentRecord.mixTime = thoiGianCan;
      currentRecord.realQty = currentWeight;
      currentRecord.loai = loaiCan;
      _standardWeight = 0.0;
      _calculateMinMax();

      if (!context.mounted) return false;
      NotificationService().showToast(
        context: context,
        message: 'Tên Phôi Keo: ${currentRecord.tenPhoiKeo}\n'
            'Số Lô: ${currentRecord.soLo}\n'
            'Đã cân: ${currentWeight.toStringAsFixed(3)} kg!',
        type: ToastType.success,
      );

      _syncService.syncHistoryQueue();
      notifyListeners();
      return true;
    } on WeighingException catch (e) {
      if (kDebugMode) print('⚖️ Lỗi nghiệp vụ cân: ${e.message}');
      if (!context.mounted) return false;
      NotificationService().showToast(context: context, message: e.message, type: ToastType.error);
      return false;
    } catch (e) {
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