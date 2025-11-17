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
  List<Map<String, dynamic>> _failedRecords = [];
  List<Map<String, dynamic>> _successRecords = [];

  @override
  void initState() {
    super.initState();
    _loadPendingData();
  }

  // 1. Tải dữ liệu từ DB Cục bộ
  Future<void> _loadPendingData() async {
    setState(() => _isLoading = true);
    final data = await _dbHelper.getPendingSyncRecords();
    final failed = await _dbHelper.getFailedSyncRecords();
    final success = await _dbHelper.getLast10SuccessfulRecords();

    setState(() {
      _pendingRecords = data;
      _failedRecords = failed;
      _successRecords = success;
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

  // 3. Định dạng thời gian (chuyển từ UTC sang local timezone)
  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      // Nếu là UTC, chuyển sang local timezone
      final localDt = dt.isUtc ? dt.toLocal() : dt;
      return DateFormat('dd/MM HH:mm:ss').format(localDt);
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
    // Nếu cả 3 danh sách trống
    if (_pendingRecords.isEmpty && _failedRecords.isEmpty && _successRecords.isEmpty) {
      return const Center(
        child: Text(
          'Không có dữ liệu nào chờ đồng bộ.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Pending section
        if (_pendingRecords.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Chưa đồng bộ (${_pendingRecords.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ..._pendingRecords.map((record) {
            final bool isNhap = record['loai'] == 'nhap';
            final weightText = '${(record['khoiLuongCan'] as num).toStringAsFixed(3)} kg';
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: 2,
              child: ListTile(
                isThreeLine: true,
                leading: CircleAvatar(
                  backgroundColor: isNhap ? Colors.green[100] : Colors.blue[100],
                  child: Icon(
                    isNhap ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isNhap ? Colors.green[800] : Colors.blue[800],
                  ),
                ),
                title: Text('${record['tenPhoiKeo'] ?? 'N/A'} (Lô: ${record['soLo']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mã: ${record['maCode']} | Cân bởi: ${record['nguoiThaoTac'] ?? 'N/A'}'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('Lúc: ${_formatTime(record['thoiGianCan'])}'),
                        const Spacer(),
                        Text(isNhap ? 'Cân Nhập' : 'Cân Xuất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isNhap ? Colors.green[700] : Colors.blue[700])),
                      ],
                    ),
                  ],
                ),
                trailing: Text(weightText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              ),
            );
          }),
        ],

        // Failed section
        if (_failedRecords.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text('Đồng bộ thất bại (${_failedRecords.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
          ),
          ..._failedRecords.map((record) {
            final bool isNhap = record['loai'] == 'nhap';
            final String errMsg = record['errorMessage'] ?? 'Lỗi không xác định';

            return Card(
              color: Colors.red[25],
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: 1,
              child: ListTile(
                isThreeLine: true,
                leading: CircleAvatar(
                  backgroundColor: isNhap ? Colors.green[50] : Colors.blue[50],
                  child: Icon(isNhap ? Icons.error : Icons.error, color: Colors.red[700]),
                ),
                title: Text('${record['tenPhoiKeo'] ?? 'N/A'} (Lô: ${record['soLo']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mã: ${record['maCode']}\nLúc: ${_formatTime(record['thoiGianCan'] ?? '')}'),
                    const SizedBox(height: 6),
                    Text(errMsg, style: const TextStyle(color: Colors.redAccent), maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${(record['khoiLuongCan'] as num).toStringAsFixed(3)} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        IconButton(
                          tooltip: 'Retry',
                          icon: const Icon(Icons.refresh, color: Colors.orange),
                          onPressed: () async {
                            if (_isSyncing) return;
                            setState(() => _isSyncing = true);
                            final success = await _syncService.retryFailedSync(record['id'] as int, record);
                            if (!mounted) return;
                            if (success) {
                              NotificationService().showToast(context: context, message: 'Đã retry thành công!', type: ToastType.success);
                            } else {
                              NotificationService().showToast(context: context, message: 'Retry thất bại hoặc chưa có mạng.', type: ToastType.error);
                            }
                            await _loadPendingData();
                            setState(() => _isSyncing = false);
                          },
                        ),
                        IconButton(
                          tooltip: 'Xóa',
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Xác nhận'),
                                content: const Text('Bạn có chắc muốn xóa bản ghi thất bại này không?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Xóa')),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await _dbHelper.deleteFailedSyncById(record['id'] as int);
                              await _loadPendingData();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],

        // Success section (last 10)
        if (_successRecords.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text('Mã đã đồng bộ thành công', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          ..._successRecords.map((record) {
            final bool isNhap = (record['loai'] ?? 'nhap') == 'nhap';
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: 1,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isNhap ? Colors.green[50] : Colors.blue[50],
                  child: Icon(isNhap ? Icons.check_circle : Icons.check_circle, color: isNhap ? Colors.green[700] : Colors.blue[700]),
                ),
                title: Text('${record['tenPhoiKeo'] ?? 'N/A'} (Lô: ${record['soLo']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Mã: ${record['maCode']}\nLúc: ${_formatTime(record['thoiGianCan'] ?? '')}'),
                trailing: Text('${(record['khoiLuongCan'] as num).toStringAsFixed(3)} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            );
          }),
        ],
      ],
    );
  }
}