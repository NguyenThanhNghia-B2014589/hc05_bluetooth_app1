import 'dart:convert';
import 'dart:io';
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
    Map<String, dynamic> data; // Di chuyển data ra ngoài
    try {
      final db = await _dbHelper.database;
      
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
        data = localData.first;
      } else {
        if (kDebugMode) {
          print('🔍 Mã $code không có trong cache, đang gọi API...');
        }
        final url = Uri.parse('$_apiBaseUrl/api/scan/$code');
        final response = await http.get(url).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          data = json.decode(response.body);

          // LƯU VÀO CACHE (SQLITE)
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
          throw WeighingException('Lỗi server: ${response.statusCode}');
        }
      }

      // --- CẬP NHẬT UI (SAU KHI ĐÃ CÓ 'data') ---
      if (!context.mounted) return;

      if (_activeOVNO == null || _activeOVNO != data['ovNO']) {
        _activeOVNO = data['ovNO'];
        _activeMemo = data['memo'];
      }
      _activeTotalTargetQty = (data['totalTargetQty'] as num? ?? 0.0).toDouble();
      _activeTotalNhap = (data['totalNhapWeighed'] as num? ?? 0.0).toDouble();
      _activeTotalXuat = (data['totalXuatWeighed'] as num? ?? 0.0).toDouble();
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
        soMay: data['soMay'].toString(), // Sửa lại
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
      
    } on TimeoutException catch (e) {
      if (kDebugMode) print('⏱️ Timeout: $e');
      if (!context.mounted) return;
      NotificationService().showToast(
        context: context, message: 'Lỗi: Hết thời gian chờ kết nối!', type: ToastType.error,
      );
    } on SocketException catch (e) {
      if (kDebugMode) print('🔌 Socket Exception: $e');
      if (!context.mounted) return;
      NotificationService().showToast(
        context: context, message: 'Không thể kết nối: Đảm bảo điện thoại và máy tính cùng mạng WiFi.', type: ToastType.error,
      );
    } on WeighingException catch (e) { // Bắt lỗi Exception tùy chỉnh
      if (kDebugMode) print('⚖️ Weighing Error: ${e.message}');
      if (!context.mounted) return;
      NotificationService().showToast(
        context: context, message: e.message, type: ToastType.error,
      );
    } catch (e) {
      if (kDebugMode) print('❌ Unknown Error: $e');
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

    if (isInRange) {
      final thoiGianCan = DateTime.now();
      final loaiCan = (_selectedWeighingType == WeighingType.nhap) ? 'nhap' : 'xuat';

      final Map<String, dynamic> localData = {
        'maCode': currentRecord.maCode,
        'khoiLuongCan': currentWeight,
        'thoiGianCan': thoiGianCan.toIso8601String(),
        'loai': loaiCan,
      };

      try {
        // 1. LƯU VÀO HÀNG ĐỢI CỤC BỘ
        final db = await _dbHelper.database;
        await db.insert('HistoryQueue', localData);

        // 2. CẬP NHẬT UI
        currentRecord.isSuccess = true;
        currentRecord.mixTime = thoiGianCan;
        currentRecord.realQty = currentWeight;
        currentRecord.loai = loaiCan;
        _standardWeight = 0.0;
        _calculateMinMax();
        
        // 3. HIỂN THỊ THÔNG BÁO THÀNH CÔNG
        if (context.mounted) {
          NotificationService().showToast(
            context: context,
            message: 'Tên Phôi Keo: ${currentRecord.tenPhoiKeo}\n'
                    'Số Lô: ${currentRecord.soLo}\n'
                    'Đã cân: ${currentWeight.toStringAsFixed(3)} kg!',
            type: ToastType.success,
          );
        }

        // 4. KIỂM TRA MẠNG VÀ THỬ ĐỒNG BỘ (CHẠY NGẦM)
        syncPendingData(); 

        notifyListeners();
        return true;

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

Future<void> syncPendingData() async {
    if (kDebugMode) {
      print('🔄 Bắt đầu quá trình đồng bộ...');
    }
    final db = await _dbHelper.database;
    
    // 1. Lấy tất cả record đang chờ trong Queue
    final List<Map<String, dynamic>> pendingRecords = await db.query('HistoryQueue');

    if (pendingRecords.isEmpty) {
      if (kDebugMode) {
        print('✅ Không có gì để đồng bộ.');
      }
      return;
    }

    if (kDebugMode) {
      print('🔄 Tìm thấy ${pendingRecords.length} record cần đồng bộ.');
    }

    // 2. Lặp qua từng record và gửi lên server
    for (var record in pendingRecords) {
      final int localId = record['id'];
      
      try {
        final url = Uri.parse('$_apiBaseUrl/api/complete');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            // Gửi dữ liệu từ bảng Queue
            'maCode': record['maCode'],
            'khoiLuongCan': record['khoiLuongCan'],
            'thoiGianCan': record['thoiGianCan'],
            'loai': record['loai'],
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 201) {
          // 3. THÀNH CÔNG: Xóa record khỏi Queue
          await db.delete('HistoryQueue', where: 'id = ?', whereArgs: [localId]);
          if (kDebugMode) {
            print('✅ Đã đồng bộ thành công ID: $localId');
          }
        
        } else if (response.statusCode >= 400 && response.statusCode < 500) {
          // 4. LỖI DỮ LIỆU (4xx): Mã này đã cân, hoặc vượt tồn kho...
          // Dữ liệu này "xấu", xóa đi để không gửi lại
          if (kDebugMode) {
            print('❌ Lỗi 4xx khi đồng bộ ID: $localId. Xóa khỏi queue.');
          }
          await db.delete('HistoryQueue', where: 'id = ?', whereArgs: [localId]);
        
        } else {
          // 5. LỖI SERVER (5xx):
          // Không xóa, giữ lại để thử lại lần sau
          if (kDebugMode) {
            print('⚠️ Lỗi 5xx khi đồng bộ ID: $localId. Sẽ thử lại sau.');
          }
        }

      } catch (e) {
        // 6. LỖI MẠNG:
        // Không xóa, giữ lại để thử lại lần sau
        if (kDebugMode) {
          print('🌐 Lỗi mạng khi đồng bộ. Sẽ thử lại sau.');
        }
        break; // Dừng vòng lặp nếu mất mạng
      }
    }
  }
}