import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/bluetooth_device.dart';

// Lớp này quản lý toàn bộ trạng thái và logic Bluetooth
class BluetoothService {
  // Singleton pattern: Đảm bảo chỉ có một thực thể của service này trong toàn bộ ứng dụng
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  // Channels
  static const _methodChannel = MethodChannel('com.hc.bluetooth.method_channel');
  static const _eventChannel = EventChannel('com.hc.bluetooth.event_channel');
  StreamSubscription? _eventSubscription;

  // Notifiers: Các widget sẽ lắng nghe những notifier này để cập nhật UI
  final ValueNotifier<List<BluetoothDevice>> scanResults = ValueNotifier([]);
  final ValueNotifier<BluetoothDevice?> connectedDevice = ValueNotifier(null);
  final ValueNotifier<String> status = ValueNotifier('Sẵn sàng');
  final ValueNotifier<double> currentWeight = ValueNotifier(0.0);
  final ValueNotifier<bool> isScanning = ValueNotifier(false);
  
  // Map nội bộ để quản lý các thiết bị đã quét
  final Map<String, BluetoothDevice> _scannedDevices = {};

  // --- THÊM CÁC BIẾN CHO VIỆC ĐIỀU TIẾT DỮ LIỆU ---
  //bool _isThrottling = false; // Biến này hoạt động như cái "cổng"
  //final int _throttleMilliseconds = 500; // Cấu hình thời gian chờ (500ms = 0.5 giây)

  // Khởi tạo service, bắt đầu lắng nghe sự kiện từ native
  void initialize() {
    if (_eventSubscription != null) return; // Chỉ khởi tạo một lần
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);
  }

  void _onEvent(dynamic event) {
    final String eventType = event['type'];
    switch (eventType) {
      case 'scanResult':
        final device = BluetoothDevice(
          name: event['name'] ?? 'N/A', address: event['address'], rssi: int.tryParse(event['rssi'] ?? '0') ?? 0,
        );
        _scannedDevices[device.address] = device;
        scanResults.value = _scannedDevices.values.toList();
        break;
      case 'status':
        status.value = event['message'];
        if (event['status'] == 'connected') {
          connectedDevice.value = _scannedDevices[event['address']];
        } else if (event['status'] == 'error' || event['status'] == 'disconnected') {
          connectedDevice.value = null;
        } else if (event['status'] == 'scanFinished') {
          isScanning.value = false;
        }
        break;
    
      case 'dataReceived':
        // Lấy dữ liệu thô và chuyển thành chuỗi String
        final String rawDataString = utf8.decode(event['data']).trim();
        
        // In ra để chẩn đoán. Đây là bước quan trọng nhất!
        //print('🔵 Dữ liệu thô nhận được: "$rawDataString"');

        // Sử dụng Biểu thức chính quy (RegExp) để tìm số trong chuỗi
        // Nó có thể tìm thấy số như "123.45" trong các chuỗi "W:123.45", "Nặng 123.45g", v.v.
        final RegExp numberRegex = RegExp(r'(\d+\.?\d*)');
        final Match? match = numberRegex.firstMatch(rawDataString);

        if (match != null) {
          // Nếu tìm thấy một số trong chuỗi
          final String numberString = match.group(1)!;
          final double? weight = double.tryParse(numberString);
          
          if (weight != null) {
            //print('✅ Parse thành công: $weight');
            currentWeight.value = weight; // Cập nhật giao diện
          } else {
            if (kDebugMode) {
              print('❌ Lỗi: Tìm thấy chuỗi số "$numberString" nhưng không parse được.');
            }
          }
        } else {
          // Nếu không tìm thấy bất kỳ số nào trong chuỗi
          if (kDebugMode) {
            print('⚠️ Không tìm thấy số nào trong chuỗi nhận được.');
          }
        }
        break;

      /* case 'dataReceived':
        // Nếu "cổng" đang đóng, bỏ qua dữ liệu và thoát ngay
        if (_isThrottling) {
          print('💧 Dữ liệu bị bỏ qua do throttling.');
          return;
        }

        // Nếu "cổng" đang mở, cho dữ liệu đi qua và đóng cổng lại ngay
        _isThrottling = true;
        
        // Lên lịch để "mở cổng" trở lại sau khoảng thời gian _throttleMilliseconds
        Future.delayed(Duration(milliseconds: _throttleMilliseconds), () {
          _isThrottling = false;
        });

        // Xử lý gói dữ liệu đã được đi qua cổng
        final String rawDataString = utf8.decode(event['data']).trim();
        print('🔵 Dữ liệu thô nhận được (đã qua throttling): "$rawDataString"');

        final RegExp numberRegex = RegExp(r'(\d+\.?\d*)');
        final Match? match = numberRegex.firstMatch(rawDataString);

        if (match != null) {
          final String numberString = match.group(1)!;
          final double? weight = double.tryParse(numberString);
          if (weight != null) {
            print('✅ Parse thành công: $weight');
            currentWeight.value = weight;
          } else {
            print('❌ Lỗi: Tìm thấy chuỗi số "$numberString" nhưng không parse được.');
          }
        } else {
          print('⚠️ Không tìm thấy số nào trong chuỗi nhận được.');
        }
        break; */
    }
  }

  void _onError(dynamic error) {
    status.value = 'Lỗi nhận sự kiện: ${error.message}';
  }

  // Các hàm public để UI có thể gọi
  Future<void> startScan() async {
    isScanning.value = true;
    status.value = 'Đang quét...';
    _scannedDevices.clear();
    scanResults.value = [];
    await _methodChannel.invokeMethod('startScan');
  }

  Future<void> stopScan() async {
    isScanning.value = false;
    status.value = 'Đã dừng quét.';
    await _methodChannel.invokeMethod('stopScan');
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    status.value = 'Đang kết nối tới ${device.name}...';
    await _methodChannel.invokeMethod('connect', {'address': device.address});
  }

  Future<void> disconnect() async {
    if (connectedDevice.value != null) {
      await _methodChannel.invokeMethod('disconnect', {'address': connectedDevice.value!.address});
      connectedDevice.value = null;
      status.value = 'Đã ngắt kết nối.';
    }
  }

  Future<void> sendData(String textData) async {
    if (connectedDevice.value == null) return;
    final Uint8List byteData = utf8.encode('$textData\n');
    await _methodChannel.invokeMethod('sendData', {
      'address': connectedDevice.value!.address,
      'data': byteData,
    });
  }

  void dispose() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }
}