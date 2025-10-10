//lib/main.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothDevice {
  final String name;
  final String address;
  final String rssi;
  BluetoothDevice({required this.name, required this.address, required this.rssi});
  @override
  bool operator ==(Object other) => other is BluetoothDevice && address == other.address;
  @override
  int get hashCode => address.hashCode;
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HC-05 Control',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const methodChannel = MethodChannel('com.hc.bluetooth.method_channel');
  static const eventChannel = EventChannel('com.hc.bluetooth.event_channel');

  StreamSubscription? _eventSubscription;
  final List<BluetoothDevice> _scanResults = [];
  final List<String> _communicationLog = []; // << Dùng để lưu log Gửi và Nhận
  String _status = 'Sẵn sàng';
  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;

  final TextEditingController _sendDataController = TextEditingController();
  final ScrollController _logScrollController = ScrollController(); // Để tự động cuộn

  @override
  void initState() {
    super.initState();
    _startListeningToEvents();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  void _startListeningToEvents() {
    _eventSubscription = eventChannel.receiveBroadcastStream().listen((dynamic event) {
      final String eventType = event['type'];
      setState(() {
        switch (eventType) {
          case 'scanResult':
            final device = BluetoothDevice(
              name: event['name'] ?? 'N/A', address: event['address'], rssi: event['rssi'],
            );
            _scanResults.removeWhere((d) => d.address == device.address);
            _scanResults.add(device);
            break;
          case 'status':
            _status = event['message'];
            if (event['status'] == 'connected') {
              _connectedDevice = _scanResults.firstWhere((d) => d.address == event['address']);
            } else if (event['status'] == 'error' || event['status'] == 'disconnected') {
              _connectedDevice = null;
            }
            break;
          // --- PHẦN QUAN TRỌNG NHẤT ---
          case 'dataReceived':
            // Chuyển đổi mảng byte nhận được thành chuỗi String (dùng UTF-8)
            final String dataString = utf8.decode(event['data']);
            _addLog('Nhận: $dataString');
            break;
        }
      });
    }, onError: (dynamic error) {
      setState(() => _status = 'Lỗi nhận sự kiện: ${error.message}');
    });
  }

  // Hàm helper để thêm log và tự động cuộn
  void _addLog(String log) {
    setState(() {
      _communicationLog.insert(0, log); // Thêm vào đầu danh sách
    });
    // Tự động cuộn xuống dưới cùng
    if (_logScrollController.hasClients) {
      _logScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendData() async {
    if (_connectedDevice == null) {
      setState(() => _status = 'Chưa có thiết bị nào được kết nối.');
      return;
    }
    if (_sendDataController.text.isEmpty) return;

    final String textToSend = _sendDataController.text;
    final Uint8List byteData = utf8.encode(textToSend);

    try {
      await methodChannel.invokeMethod('sendData', {
        'address': _connectedDevice!.address, 'data': byteData,
      });
      _addLog('Gửi: $textToSend');
      _sendDataController.clear();
    } on PlatformException catch (e) {
      setState(() => _status = "Lỗi khi gửi: '${e.message}'.");
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_connectedDevice == null ? 'Bluetooth Scanner' : 'Điều khiển ${_connectedDevice!.name}'),
        actions: [
          if (_connectedDevice == null)
            _isScanning
              ? IconButton(icon: const Icon(Icons.stop), onPressed: _stopScan)
              : IconButton(icon: const Icon(Icons.search), onPressed: _startScan),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_status, style: Theme.of(context).textTheme.titleMedium),
          ),
          const Divider(),
          if (_connectedDevice == null)
            Expanded(
              child: ListView.builder(
                itemCount: _scanResults.length,
                itemBuilder: (context, index) {
                  final device = _scanResults[index];
                  return ListTile(
                    title: Text(device.name),
                    subtitle: Text(device.address),
                    trailing: Text('RSSI: ${device.rssi}'),
                    onTap: () => _connectToDevice(device),
                  );
                },
              ),
            )
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // --- KHU VỰC HIỂN THỊ LOG GIAO TIẾP ---
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: ListView.builder(
                          controller: _logScrollController,
                          reverse: true, // Hiển thị log mới nhất ở trên cùng
                          itemCount: _communicationLog.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: Text(_communicationLog[index]),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // --- KHU VỰC GỬI DỮ LIỆU ---
                    TextField(
                      controller: _sendDataController,
                      decoration: InputDecoration(
                        labelText: 'Nhập dữ liệu để gửi',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _sendData,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Dán lại các hàm không thay đổi để đảm bảo tính toàn vẹn
  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() { _status = 'Đang yêu cầu kết nối tới ${device.name}...'; });
    try {
      await methodChannel.invokeMethod('connect', {'address': device.address});
    } on PlatformException catch (e) {
      setState(() { _status = "Lỗi khi kết nối: '${e.message}'."; });
    }
  }
  Future<void> _startScan() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan, Permission.bluetoothConnect, Permission.locationWhenInUse,
    ].request();
    if (statuses.values.every((status) => status == PermissionStatus.granted)) {
      setState(() { _scanResults.clear(); _isScanning = true; _status = 'Đang quét...'; });
      try { await methodChannel.invokeMethod('startScan'); } on PlatformException catch (e) {
        setState(() { _status = "Lỗi khi quét: '${e.message}'."; _isScanning = false; });
      }
    } else {
      setState(() { _status = 'Cần cấp quyền Bluetooth và Vị trí để quét.'; });
    }
  }
  Future<void> _stopScan() async {
    try {
      await methodChannel.invokeMethod('stopScan');
      setState(() { _isScanning = false; _status = 'Đã dừng quét.'; });
    } on PlatformException catch (e) {
      setState(() { _status = "Lỗi khi dừng quét: '${e.message}'."; });
    }
  }
}