import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart'; // Import DB Helper

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

    } catch (e) {
      if (kDebugMode) {
        print('❌ Lỗi đồng bộ dữ liệu: $e');
      }
      // Ném lỗi để LoginScreen có thể bắt
      throw Exception('Lỗi đồng bộ: $e');
    }
  }
}