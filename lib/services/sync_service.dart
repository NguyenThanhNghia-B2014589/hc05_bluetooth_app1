import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // <-- 1. THÊM IMPORT

class SyncService {
  final String _apiBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3636';
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> syncAllData() async {
    if (kDebugMode) {
      print('🔄 Bắt đầu đồng bộ TẤT CẢ dữ liệu chưa cân...');
    }
    try {
      // 1. Gọi API để lấy dữ liệu mới
      final url = Uri.parse('$_apiBaseUrl/api/sync/unweighed');
      final response = await http.get(url).timeout(const Duration(seconds: 30)); // Cho 30s

      if (response.statusCode != 200) {
        throw Exception('API Sync thất bại: ${response.statusCode}');
      }

      final List<dynamic> data = json.decode(response.body);
      if (kDebugMode) {
        print('🔄 Tải về ${data.length} bản ghi chưa cân.');
      }

      // 2. Lấy DB và bắt đầu "Batch" (Giao dịch hàng loạt)
      final db = await _dbHelper.database;
      final batch = db.batch();

      // 3. XÓA SẠCH CACHE CŨ
      // (Để đảm bảo các mã ĐÃ CÂN bởi người khác cũng bị xóa)
      batch.delete('VmlWorkS');
      batch.delete('VmlWork');
      batch.delete('VmlPersion');

      // 4. Lặp qua dữ liệu mới và "Nhồi" (Populate)
      for (var item in data) {
        // Dùng 'insert OR REPLACE' để cập nhật
        
        // Thêm vào VmlWorkS
        batch.insert('VmlWorkS', {
          'maCode': item['maCode'],
          'ovNO': item['ovNO'],
          'package': item['package'],
          'mUserID': item['mUserID']?.toString(),
          'qtys': item['qtys'],
          'realQty': item['realQty'],
          'mixTime': item['mixTime'],
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        
        // Thêm vào VmlWork
        batch.insert('VmlWork', {
          'ovNO': item['ovNO'],
          'tenPhoiKeo': item['tenPhoiKeo'],
          'soMay': item['soMay']?.toString(),
          'memo': item['memo'],
          'totalTargetQty': item['totalTargetQty'],
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        
        // Thêm vào VmlPersion
        batch.insert('VmlPersion', {
          'mUserID': item['mUserID']?.toString(),
          'nguoiThaoTac': item['nguoiThaoTac'],
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // 5. Commit batch
      await batch.commit(noResult: true);
      if (kDebugMode) {
        print('✅ Đồng bộ thành công ${data.length} bản ghi vào cache.');
      }

      await syncHistoryQueue();

    } catch (e) {
      if (kDebugMode) {
        print('❌ Lỗi đồng bộ dữ liệu: $e');
      }
      // Ném lỗi để LoginScreen có thể bắt
      throw Exception('Lỗi đồng bộ: $e');
    }
    if (kDebugMode) {
      print('🔄 Đồng bộ HistoryQueue hoàn tất.');
    }
  }

  Future<void> syncHistoryQueue() async {
    if (kDebugMode) {
      print('🔄 Bắt đầu đồng bộ HistoryQueue...');
    }
    final db = await _dbHelper.database;
    
    // Kiểm tra mạng trước
    final connectivityResult = await Connectivity().checkConnectivity();
    if (!connectivityResult.contains(ConnectivityResult.wifi) && 
        !connectivityResult.contains(ConnectivityResult.mobile)) {
      if (kDebugMode) {
        print('🌐 Không có mạng, hủy đồng bộ Queue.');
      }
      return; 
    }

    final List<Map<String, dynamic>> pendingRecords = await db.query('HistoryQueue');

    if (pendingRecords.isEmpty) {
      if (kDebugMode) {
        print('✅ Queue trống, không có gì để đồng bộ.');
      }
      return;
    }

    if (kDebugMode) {
      print('🔄 Tìm thấy ${pendingRecords.length} record trong Queue cần đồng bộ.');
    }

    for (var record in pendingRecords) {
      final int localId = record['id'];
      
      try {
        final url = Uri.parse('$_apiBaseUrl/api/complete');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'maCode': record['maCode'],
            'khoiLuongCan': record['khoiLuongCan'],
            'thoiGianCan': record['thoiGianCan'],
            'loai': record['loai'],
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 201) {
          await db.delete('HistoryQueue', where: 'id = ?', whereArgs: [localId]);
          if (kDebugMode) {
            print('✅ Đã đồng bộ thành công ID Queue: $localId');
          }
        
        } else if (response.statusCode >= 400 && response.statusCode < 500) {
          if (kDebugMode) {
            print('❌ Lỗi 4xx khi đồng bộ ID Queue: $localId. Xóa khỏi queue.');
          }
          await db.delete('HistoryQueue', where: 'id = ?', whereArgs: [localId]);
        
        } else {
          if (kDebugMode) {
            print('⚠️ Lỗi 5xx khi đồng bộ ID Queue: $localId. Sẽ thử lại sau.');
          }
        }

      } catch (e) {
        if (kDebugMode) {
          print('🌐 Lỗi mạng khi đồng bộ ID Queue: $localId. Sẽ thử lại sau.');
        }
        break; 
      }
    }
    if (kDebugMode) {
      print('🔄 Đồng bộ HistoryQueue hoàn tất.');
    }
  }
}
