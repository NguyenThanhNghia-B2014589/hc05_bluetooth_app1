import 'package:flutter/material.dart';
import '../../services/bluetooth_service.dart';
import '../../services/notification_service.dart';
import './controllers/weighing_station_controller.dart';

// Import các widget con
import 'widgets/current_weight_card.dart';
import 'widgets/action_min_max.dart';
import 'widgets/scan_input_field.dart';
import 'widgets/weighing_table.dart';

class WeighingStationScreen extends StatefulWidget {
  const WeighingStationScreen({super.key});

  @override
  State<WeighingStationScreen> createState() => _WeighingStationScreenState();
}

class _WeighingStationScreenState extends State<WeighingStationScreen> {
  // --- SỬ DỤNG DỊCH VỤ BLUETOOTH CHUNG ---
  final BluetoothService _bluetoothService = BluetoothService();
  late final WeighingStationController _controller;


  @override
  void initState() {
    super.initState();
    // --- KHỞI TẠO CONTROLLER ---
    _controller = WeighingStationController(bluetoothService: _bluetoothService);
    
    _bluetoothService.connectedDevice.addListener(_onConnectionChange);
  }

  @override
  void dispose() {
    _bluetoothService.connectedDevice.removeListener(_onConnectionChange);
    _controller.dispose();
    super.dispose();
  }

  void _onConnectionChange() {
    if (_bluetoothService.connectedDevice.value == null && mounted) {
      Navigator.of(context).pushReplacementNamed('/scan');
    }
  }

  @override
   Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('LƯU TRÌNH CÂN KEO XƯỞNG ĐẾ', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false, 
        actions: [
          const Icon(Icons.person, color: Colors.black54),
          const SizedBox(width: 8),
          Text(_bluetoothService.connectedDevice.value?.name ?? 'HC-05', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
          
          IconButton(
            icon: const Icon(Icons.link_off),
            tooltip: 'Ngắt kết nối',
            onPressed: () {
              _bluetoothService.disconnect();
              NotificationService().showToast(
                context: context,
                message: 'Đã ngắt kết nối với ${_bluetoothService.connectedDevice.value!.name}!',
                type: ToastType.info,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Hàm _buildLayout bây giờ nằm bên trong builder
              return _buildLayout();
            },
          );
        },
      ),
    );
  }

  // Widget layout chính
  Widget _buildLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trạm Cân', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cột bên trái
              Expanded(flex: 2, child: CurrentWeightCard(bluetoothService: _bluetoothService)),
              const SizedBox(width: 24),
              // Cột bên phải
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    const SizedBox(height: 5),
                    ActionBar(
                      selectedPercentage: _controller.selectedPercentage,
                      minWeight: _controller.minWeight,
                      maxWeight: _controller.maxWeight,
                      onPercentageChanged: _controller.updatePercentage,
                    ), // << WIDGET CHO ACTION BAR
                    const SizedBox(height: 20),
                    ScanInputField(onScan: (code) => _controller.handleScan(context, code)), // WIDGET SCAN
                    const SizedBox(height: 20),
                    // Nút hoàn tất
                    ElevatedButton(
                      onPressed: () {
                        NotificationService().showToast(
                          context: context,
                          message: 'Cân hoàn tất!',
                          type: ToastType.success,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8EAF6),
                        foregroundColor: Colors.indigo,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text('Hoàn tất'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          WeighingTable(records: _controller.records), // Bảng cân
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}