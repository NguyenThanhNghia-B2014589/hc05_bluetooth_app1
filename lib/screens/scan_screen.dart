import 'package:flutter/material.dart';
import '../models/bluetooth_device.dart';
import '../services/bluetooth_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final BluetoothService _bluetoothService = BluetoothService();

  @override
  void initState() {
    super.initState();
    _bluetoothService.initialize();
    _bluetoothService.connectedDevice.addListener(_onConnectionChange);
  }

  @override
  void dispose() {
    _bluetoothService.connectedDevice.removeListener(_onConnectionChange);
    super.dispose();
  }
  
  void _onConnectionChange() {
    if (_bluetoothService.connectedDevice.value != null && mounted) {
      // Khi kết nối thành công, chuyển sang màn hình Trạm Cân
      Navigator.of(context).pushReplacementNamed('/weighing_station');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm thiết bị Bluetooth'),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _bluetoothService.isScanning,
            builder: (context, isScanning, child) {
              return isScanning
                  ? IconButton(icon: const Icon(Icons.stop), onPressed: _bluetoothService.stopScan)
                  : IconButton(icon: const Icon(Icons.search), onPressed: _bluetoothService.startScan);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ValueListenableBuilder<String>(
            valueListenable: _bluetoothService.status,
            builder: (context, status, child) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(status),
            ),
          ),
          const Divider(),
          Expanded(
            child: ValueListenableBuilder<List<BluetoothDevice>>(
              valueListenable: _bluetoothService.scanResults,
              builder: (context, results, child) {
                if (results.isEmpty) {
                  return const Center(child: Text('Không tìm thấy thiết bị nào.'));
                }
                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final device = results[index];
                    return ListTile(
                      leading: const Icon(Icons.bluetooth),
                      title: Text(device.name),
                      subtitle: Text(device.address),
                      trailing: Text('RSSI: ${device.rssi}'),
                      onTap: () => _bluetoothService.connectToDevice(device),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}