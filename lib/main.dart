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

// Class để lưu log chi tiết hơn
class LogMessage {
  final String message;
  final bool isSent;
  final DateTime timestamp;
  final List<int>? rawBytes; // Thêm raw bytes để hiển thị HEX
  
  LogMessage({
    required this.message, 
    required this.isSent, 
    DateTime? timestamp,
    this.rawBytes,
  }) : timestamp = timestamp ?? DateTime.now();
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
int _receiveVelocity = 2; // Mặc định tốc độ nhận dữ liệu
class _MyHomePageState extends State<MyHomePage> {
  static const methodChannel = MethodChannel('com.hc.bluetooth.method_channel');
  static const eventChannel = EventChannel('com.hc.bluetooth.event_channel');

  StreamSubscription? _eventSubscription;
  final List<BluetoothDevice> _scanResults = [];
  final List<LogMessage> _communicationLog = []; // Đổi từ String sang LogMessage
  String _status = 'Sẵn sàng';
  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;

  final TextEditingController _sendDataController = TextEditingController();
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _startListeningToEvents();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _sendDataController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  void _startListeningToEvents() {
    _eventSubscription = eventChannel.receiveBroadcastStream().listen((dynamic event) {
      final String eventType = event['type'];
      print('🔔 Event nhận được: $eventType'); // LOG DEBUG
      
      setState(() {
        switch (eventType) {
          case 'scanResult':
            final device = BluetoothDevice(
              name: event['name'] ?? 'N/A',
              address: event['address'],
              rssi: event['rssi'],
            );
            print('📡 Quét thấy: ${device.name} (${device.address})'); // LOG
            _scanResults.removeWhere((d) => d.address == device.address);
            _scanResults.add(device);
            break;
          case 'status':
            _status = event['message'];
            print('ℹ️ Trạng thái: ${event['status']} - ${event['message']}'); // LOG
            if (event['status'] == 'connected') {
              _connectedDevice = _scanResults.firstWhere(
                (d) => d.address == event['address']
              );
              _addSystemLog('🔗 Đã kết nối với ${_connectedDevice!.name}');
            } else if (event['status'] == 'error' || 
                       event['status'] == 'disconnected') {
              if (_connectedDevice != null) {
                _addSystemLog('❌ Mất kết nối với ${_connectedDevice!.name}');
              }
              _connectedDevice = null;
            }
            break;
          case 'dataReceived':
            final String dataString = utf8.decode(event['data']).trim();
            print('📥 Nhận dữ liệu: "$dataString"'); // LOG
            _addLog(dataString, isSent: false);
            break;
        }
      });
    }, onError: (dynamic error) {
      print('❌ Lỗi event: ${error.message}'); // LOG
      setState(() => _status = 'Lỗi nhận sự kiện: ${error.message}');
    });
  }

  // Thêm log giao tiếp (gửi/nhận)
  void _addLog(String message, {required bool isSent, List<int>? rawBytes}) {
    setState(() {
      _communicationLog.insert(0, LogMessage(
        message: message, 
        isSent: isSent,
        rawBytes: rawBytes,
      ));
      // Giới hạn log tối đa 100 dòng
      if (_communicationLog.length > 100) {
        _communicationLog.removeLast();
      }
    });
    _scrollToTop();
  }

  // Thêm log hệ thống (kết nối/ngắt kết nối)
  void _addSystemLog(String message) {
    setState(() {
      _communicationLog.insert(0, LogMessage(
        message: message,
        isSent: false, // Dùng style khác
      ));
    });
    _scrollToTop();
  }

  void _scrollToTop() {
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
      print('⚠️ Chưa có thiết bị kết nối'); // LOG
      setState(() => _status = 'Chưa có thiết bị nào được kết nối.');
      return;
    }
    if (_sendDataController.text.isEmpty) return;

    final String textToSend = _sendDataController.text;
    final Uint8List byteData = utf8.encode(textToSend + '\n');

    print('📤 Chuẩn bị gửi: "$textToSend" (${byteData.length} bytes)'); // LOG

    try {
      await methodChannel.invokeMethod('sendData', {
        'address': _connectedDevice!.address,
        'data': byteData,
      });
      print('✅ Gửi thành công: "$textToSend"'); // LOG
      _addLog(textToSend, isSent: true);
      _sendDataController.clear();
    } on PlatformException catch (e) {
      print('❌ Lỗi gửi dữ liệu: ${e.message}'); // LOG
      setState(() => _status = "Lỗi khi gửi: '${e.message}'.");
    }
  }

  // Hàm gửi lệnh nhanh
  Future<void> _sendQuickCommand(String command) async {
    if (_connectedDevice == null) {
      setState(() => _status = 'Chưa có thiết bị nào được kết nối.');
      return;
    }

    final Uint8List byteData = utf8.encode(command + '\n');
    print('📤 Gửi lệnh nhanh: "$command"');

    try {
      await methodChannel.invokeMethod('sendData', {
        'address': _connectedDevice!.address,
        'data': byteData,
      });
      _addLog(command, isSent: true);
    } on PlatformException catch (e) {
      print('❌ Lỗi gửi lệnh: ${e.message}');
      setState(() => _status = "Lỗi khi gửi: '${e.message}'.");
    }
  }

  // Widget nút lệnh nhanh
  Widget _buildQuickButton(String command) {
    return ElevatedButton(
      onPressed: () => _sendQuickCommand(command),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
      ),
      child: Text(command, style: const TextStyle(fontSize: 12)),
    );
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    print('🔌 Đang kết nối tới: ${device.name} (${device.address})'); // LOG
    setState(() {
      _status = 'Đang yêu cầu kết nối tới ${device.name}...';
    });
    try {
      await methodChannel.invokeMethod('connect', {'address': device.address});
      // Đặt tốc độ mặc định sau khi kết nối
      await _setReceiveVelocity(_receiveVelocity);
    } on PlatformException catch (e) {
      print('❌ Kết nối thất bại: ${e.message}'); // LOG
      setState(() {
        _status = "Lỗi khi kết nối: '${e.message}'.";
      });
    }
  }

  Future<void> _setReceiveVelocity(int level) async {
    if (_connectedDevice == null) return;
    try {
      await methodChannel.invokeMethod('setVelocity', {
        'address': _connectedDevice!.address,
        'level': level,
      });
      setState(() => _receiveVelocity = level);
      print('⚙️ Đã đặt tốc độ nhận: $level');
    } on PlatformException catch (e) {
      print('❌ Lỗi đặt tốc độ: ${e.message}');
    }
  }

  Future<void> _disconnectFromDevice() async {
    if (_connectedDevice == null) return;
    try {
      await methodChannel.invokeMethod('disconnect', {
        'address': _connectedDevice!.address
      });
      setState(() {
        _connectedDevice = null;
        _status = 'Đã ngắt kết nối';
        _communicationLog.clear();
      });
    } on PlatformException catch (e) {
      setState(() => _status = "Lỗi khi ngắt kết nối: '${e.message}'.");
    }
  }

  Future<void> _startScan() async {
    print('🔍 Bắt đầu quét Bluetooth...'); // LOG
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    
    if (statuses.values.every((status) => status == PermissionStatus.granted)) {
      setState(() {
        _scanResults.clear();
        _isScanning = true;
        _status = 'Đang quét...';
      });
      try {
        await methodChannel.invokeMethod('startScan');
        print('✅ Đã gọi startScan()'); // LOG
      } on PlatformException catch (e) {
        print('❌ Lỗi khi quét: ${e.message}'); // LOG
        setState(() {
          _status = "Lỗi khi quét: '${e.message}'.";
          _isScanning = false;
        });
      }
    } else {
      print('⚠️ Chưa cấp đủ quyền: $statuses'); // LOG
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
      });
    }
  }

  // Widget hiển thị 1 dòng log
  Widget _buildLogItem(LogMessage log) {
    // Format thời gian đơn giản không cần intl
    final hour = log.timestamp.hour.toString().padLeft(2, '0');
    final minute = log.timestamp.minute.toString().padLeft(2, '0');
    final second = log.timestamp.second.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute:$second';
    
    // Phát hiện log hệ thống (có emoji)
    final isSystemLog = log.message.startsWith('🔗') || log.message.startsWith('❌');
    
    // Chuyển raw bytes thành HEX string
    String? hexString;
    if (log.rawBytes != null && log.rawBytes!.isNotEmpty) {
      hexString = log.rawBytes!
          .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(' ');
    }
    
    if (isSystemLog) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                log.message,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: log.isSent ? Colors.blue[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: log.isSent ? Colors.blue[200]! : Colors.green[200]!,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: log.isSent ? Colors.blue[100] : Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              log.isSent ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: log.isSent ? Colors.blue[700] : Colors.green[700],
            ),
          ),
          const SizedBox(width: 12),
          // Nội dung
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.isSent ? 'GỬI ĐI' : 'NHẬN VỀ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: log.isSent ? Colors.blue[700] : Colors.green[700],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                // Hiển thị TEXT
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    log.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[900],
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Hiển thị HEX nếu có
                if (hexString != null) ...[
                  const SizedBox(height: 6),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      'HEX (${log.rawBytes!.length} bytes)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SelectableText(
                          hexString,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[800],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_connectedDevice == null
            ? 'Bluetooth Scanner'
            : 'Điều khiển ${_connectedDevice!.name}'),
        actions: [
          if (_connectedDevice == null)
            _isScanning
                ? IconButton(icon: const Icon(Icons.stop), onPressed: _stopScan)
                : IconButton(icon: const Icon(Icons.search), onPressed: _startScan)
          else
            Row(
              children: [
                // Menu tốc độ nhận dữ liệu
                PopupMenuButton<int>(
                  icon: const Icon(Icons.speed),
                  tooltip: 'Tốc độ nhận dữ liệu',
                  onSelected: _setReceiveVelocity,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 1,
                      child: Row(
                        children: [
                          Icon(Icons.speed, color: _receiveVelocity == 1 ? Colors.blue : Colors.grey),
                          const SizedBox(width: 8),
                          const Text('Chậm (1104ms)'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 2,
                      child: Row(
                        children: [
                          Icon(Icons.speed, color: _receiveVelocity == 2 ? Colors.blue : Colors.grey),
                          const SizedBox(width: 8),
                          const Text('Trung bình (120ms)'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 3,
                      child: Row(
                        children: [
                          Icon(Icons.speed, color: _receiveVelocity == 3 ? Colors.blue : Colors.grey),
                          const SizedBox(width: 8),
                          const Text('Nhanh (60ms)'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 4,
                      child: Row(
                        children: [
                          Icon(Icons.speed, color: _receiveVelocity == 4 ? Colors.blue : Colors.grey),
                          const SizedBox(width: 8),
                          const Text('Rất nhanh (20ms)'),
                        ],
                      ),
                    ),
                  ],
                ),
                // Nút xóa log
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    setState(() => _communicationLog.clear());
                  },
                  tooltip: 'Xóa log',
                ),
                // Nút ngắt kết nối
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _disconnectFromDevice,
                  tooltip: 'Ngắt kết nối',
                ),
              ],
            ),
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
                    leading: const Icon(Icons.bluetooth, color: Colors.blue),
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
                    // Header log
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.history, size: 16, color: Colors.grey[700]),
                          const SizedBox(width: 8),
                          Text(
                            'NHẬT KÝ GIAO TIẾP (${_communicationLog.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Log list
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                        ),
                        child: _communicationLog.isEmpty
                            ? Center(
                                child: Text(
                                  'Chưa có dữ liệu giao tiếp',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              )
                            : ListView.builder(
                                controller: _logScrollController,
                                reverse: true,
                                padding: const EdgeInsets.all(8),
                                itemCount: _communicationLog.length,
                                itemBuilder: (context, index) => _buildLogItem(_communicationLog[index]),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Nút lệnh nhanh
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickButton('GET_DATA'),
                        _buildQuickButton('GET_TEMP'),
                        _buildQuickButton('READ'),
                        _buildQuickButton('STATUS'),
                        _buildQuickButton('?'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Input gửi dữ liệu
                    TextField(
                      controller: _sendDataController,
                      decoration: InputDecoration(
                        labelText: 'Nhập lệnh hoặc dữ liệu',
                        hintText: 'VD: LED_ON, TEMP?, etc.',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.edit),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send, color: Colors.blue),
                          onPressed: _sendData,
                        ),
                      ),
                      onSubmitted: (_) => _sendData(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}