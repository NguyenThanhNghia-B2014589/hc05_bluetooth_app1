import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';


void main() {
  runApp(const MyApp());
}

// Lớp để chứa thông tin thiết bị Bluetooth
class BluetoothDevice {
  final String name;
  final String address;
  final String rssi;

  BluetoothDevice({required this.name, required this.address, required this.rssi});
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BluetoothDevice &&
          runtimeType == other.runtimeType &&
          address == other.address;
  @override
  int get hashCode => address.hashCode;
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HC-05 Bluetooth Demo',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const methodChannel = MethodChannel('com.hc.bluetooth.method_channel');
  static const eventChannel = EventChannel('com.hc.bluetooth.event_channel');

  StreamSubscription? _eventSubscription;
  final List<BluetoothDevice> _scanResults = [];
  String _status = 'Nhấn nút quét để bắt đầu';
  bool _isScanning = false;

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
      // Xử lý các loại sự kiện khác nhau từ native
      final eventType = event['type'];

      if (eventType == 'scanResult') {
        final device = BluetoothDevice(
          name: event['name'] ?? 'Unknown Device',
          address: event['address'] ?? 'Unknown Address',
          rssi: event['rssi'] ?? 'N/A',
        );
        setState(() {
          _scanResults.removeWhere((d) => d.address == device.address);
          _scanResults.add(device);
        });
      } else if (eventType == 'status') {
        setState(() {
          _status = event['message'];
        });
      }
    }, onError: (dynamic error) {
      setState(() {
        _status = 'Lỗi nhận sự kiện: ${error.message}';
      });
    });
  }

  Future<void> _startScan() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse, // Thêm quyền này cho chắc chắn
    ].request();

    if (statuses.values.every((status) => status == PermissionStatus.granted)) {
      setState(() {
        _scanResults.clear();
        _isScanning = true;
        _status = 'Đang quét...';
      });
      try {
        await methodChannel.invokeMethod('startScan');
      } on PlatformException catch (e) {
        setState(() {
          _status = "Lỗi khi quét: '${e.message}'.";
          _isScanning = false;
        });
      }
    } else {
      setState(() {
        _status = 'Cần cấp quyền Bluetooth và Vị trí để quét.';
      });
    }
  }

  Future<void> _stopScan() async {
    try {
      await methodChannel.invokeMethod('stopScan');
      setState(() {
        _isScanning = false;
        _status = 'Đã dừng quét.';
      });
    } on PlatformException catch (e) {
      setState(() {
        _status = "Lỗi khi dừng quét: '${e.message}'.";
        _isScanning = false;
      });
    }
  }

  Future<void> _connectToDevice(String address) async {
    setState(() {
      _status = 'Đang yêu cầu kết nối tới thiết bị...';
    });
    try {
      await methodChannel.invokeMethod('connect', {'address': address});
    } on PlatformException catch (e) {
       setState(() {
        _status = "Lỗi khi kết nối: '${e.message}'.";
      });
    }
  }

  Future<void> _sendData(String address, String data) async {
    if (data.isEmpty) return;
    try {
      // Chuyển đổi chuỗi String thành mảng byte Uint8List
      final Uint8List byteData = Uint8List.fromList(data.codeUnits);
      await methodChannel.invokeMethod('sendData', {'address': address, 'data': byteData});
    } on PlatformException catch (e) {
       setState(() {
        _status = "Lỗi khi gửi: '${e.message}'.";
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Scanner'),
        actions: [
          _isScanning
              ? IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: _stopScan,
                )
              : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _startScan,
                ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_status, textAlign: TextAlign.center),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _scanResults.length,
              itemBuilder: (context, index) {
                final device = _scanResults[index];
                return ListTile(
                  title: Text(device.name),
                  subtitle: Text(device.address),
                  trailing: Text('RSSI: ${device.rssi}'),
                  onTap: () => _connectToDevice(device.address),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}