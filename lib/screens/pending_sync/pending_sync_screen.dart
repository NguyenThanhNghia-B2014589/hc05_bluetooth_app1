import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/database_helper.dart';
import '../../services/sync_service.dart'; // Import SyncService
import '../../services/notification_service.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class PendingSyncScreen extends StatefulWidget {
  const PendingSyncScreen({super.key});

  @override
  State<PendingSyncScreen> createState() => _PendingSyncScreenState();
}

class _PendingSyncScreenState extends State<PendingSyncScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SyncService _syncService = SyncService();
  
  bool _isLoading = true;
  bool _isSyncing = false;
  List<Map<String, dynamic>> _pendingRecords = [];

  @override
  void initState() {
    super.initState();
    _loadPendingData();
  }

  // 1. Tải dữ liệu từ DB Cục bộ
  Future<void> _loadPendingData() async {
    setState(() => _isLoading = true);
    final data = await _dbHelper.getPendingSyncRecords();
    setState(() {
      _pendingRecords = data;
      _isLoading = false;
    });
  }

  // 2. Chạy đồng bộ thủ công
  Future<void> _runSync() async {
    setState(() => _isSyncing = true);
    // 1. Kiểm tra mạng ngay lập tức
    final connectivityResult = await Connectivity().checkConnectivity();
    if (!connectivityResult.contains(ConnectivityResult.wifi) && 
        !connectivityResult.contains(ConnectivityResult.mobile)) 
    {
      if (mounted) {
        NotificationService().showToast(
          context: context,
          message: 'Không có kết nối mạng. Vui lòng thử lại sau.',
          type: ToastType.error,
        );
      }
      setState(() => _isSyncing = false);
      return; // Dừng lại, không chạy sync
    }
    
    try {
      await _syncService.syncHistoryQueue(); // Gọi hàm sync
      
      if (mounted) {
        NotificationService().showToast(
          context: context,
          message: 'Đồng bộ hoàn tất!',
          type: ToastType.success,
        );
      }
      
      // Tải lại danh sách (giờ nó sẽ rỗng)
      await _loadPendingData();

    } catch (e) {
      if (kDebugMode) { // Đảm bảo bạn đã import 'package:flutter/foundation.dart';
        print('--- LỖI ĐỒNG BỘ (PendingSyncScreen) ---');
        print(e);
        print('------------------------------------');
      }

      // Hiển thị thông báo thân thiện cho người dùng
      if (mounted) {
        NotificationService().showToast(
          context: context,
          message: 'Lỗi kết nối máy chủ. Vui lòng kiểm tra lại mạng và thử lại.',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  // 3. Định dạng thời gian
  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('dd/MM HH:mm:ss').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dữ liệu cân chờ (Offline)'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSyncing ? null : _runSync,
        icon: _isSyncing 
            ? const CircularProgressIndicator(color: Colors.white) 
            : const Icon(Icons.sync),
        label: _isSyncing ? const Text('Đang đồng bộ...') : const Text('Đồng bộ ngay'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildBody() {
    if (_pendingRecords.isEmpty) {
      return const Center(
        child: Text(
          'Không có dữ liệu nào chờ đồng bộ.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _pendingRecords.length,
      itemBuilder: (context, index) {
        final record = _pendingRecords[index];
        final bool isNhap = record['loai'] == 'nhap';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isNhap ? Colors.green[100] : Colors.blue[100],
              child: Icon(
                isNhap ? Icons.arrow_downward : Icons.arrow_upward,
                color: isNhap ? Colors.green[800] : Colors.blue[800],
              ),
            ),
            title: Text(
              '${record['tenPhoiKeo'] ?? 'N/A'} (Lô: ${record['soLo']})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Mã: ${record['maCode']} | Cân bởi: ${record['nguoiThaoTac'] ?? 'N/A'}\n'
              'Lúc: ${_formatTime(record['thoiGianCan'])}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 1. Khối lượng
                Text(
                  '${(record['khoiLuongCan'] as double).toStringAsFixed(3)} kg',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                // 2. Loại cân (MỚI)
                Text(
                  isNhap ? 'Cân Nhập' : 'Cân Xuất',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isNhap ? Colors.green[700] : Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}