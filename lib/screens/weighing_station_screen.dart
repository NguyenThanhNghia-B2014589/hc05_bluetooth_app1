import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';

class WeighingStationScreen extends StatefulWidget {
  const WeighingStationScreen({super.key});

  @override
  State<WeighingStationScreen> createState() => _WeighingStationScreenState();
}

class _WeighingStationScreenState extends State<WeighingStationScreen> {
  final BluetoothService _bluetoothService = BluetoothService();

  @override
  void initState() {
    super.initState();
    // Lắng nghe sự kiện mất kết nối để quay về màn hình Scan
    _bluetoothService.connectedDevice.addListener(_onConnectionChange);
  }

  @override
  void dispose() {
    _bluetoothService.connectedDevice.removeListener(_onConnectionChange);
    super.dispose();
  }

  void _onConnectionChange() {
    if (_bluetoothService.connectedDevice.value == null && mounted) {
      // Khi mất kết nối, quay về màn hình Scan
      Navigator.of(context).pushReplacementNamed('/scan');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LƯU TRÌNH CÂN KEO XƯƠNG ĐẾ'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                const Icon(Icons.person),
                const SizedBox(width: 8),
                Text(_bluetoothService.connectedDevice.value?.name ?? 'HC-05'),
              ],
            )
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Dùng LayoutBuilder để xác định kích thước màn hình
          if (constraints.maxWidth > 700) { // Điểm breakpoint cho tablet
            return _buildWideLayout(); // Giao diện màn hình lớn
          } else {
            return _buildNarrowLayout(); // Giao diện màn hình nhỏ
          }
        },
      ),
    );
  }

  // Giao diện cho điện thoại (hình 1)
  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text('Trạm Cân'),
          const SizedBox(height: 20),
          _buildCurrentWeightCard(),
          const SizedBox(height: 20),
          _buildInfoCards(),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () {}, child: const Text('Hoàn tất')),
          const SizedBox(height: 20),
          const Text('Vui lòng quét mã để hiển thị thông tin'),
          const SizedBox(height: 20),
          _buildScanInput(),
        ],
      ),
    );
  }
  
  // Giao diện cho tablet (hình 2)
  Widget _buildWideLayout() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trạm Cân', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildCurrentWeightCard()),
              const SizedBox(width: 24),
              Expanded(flex: 3, child: _buildInfoCards()),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(onPressed: () {}, child: const Text('Hoàn tất')),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          // Bảng dữ liệu (để đơn giản, ta dùng Text)
          const Center(child: Text('Vui lòng quét mã để hiển thị thông tin')),
          const Spacer(),
          _buildScanInput(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Widget hiển thị trọng lượng hiện tại (dùng chung cho cả 2 layout)
  Widget _buildCurrentWeightCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trọng lượng hiện tại', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            ValueListenableBuilder<double>(
              valueListenable: _bluetoothService.currentWeight,
              builder: (context, weight, child) {
                return Text(
                  weight.toStringAsFixed(1), // Hiển thị 1 chữ số thập phân
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                );
              },
            ),
            const Text('g'),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Nhập cân nặng',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text('Chênh lệch: 0%'),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: 0.0, color: Colors.red),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị các thông tin khác (dùng chung)
  Widget _buildInfoCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _buildInfoCard('TIÊU CHUẨN', '0.0 g'),
        _buildInfoCard('% TỐI ĐA', '3%'),
        _buildInfoCard('MIN', '0.0 g'),
        _buildInfoCard('MAX', '0.0 g'),
      ],
    );
  }
  
  Widget _buildInfoCard(String title, String value) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
  
  // Widget input quét mã (dùng chung)
  Widget _buildScanInput() {
    return TextField(
      decoration: InputDecoration(
        labelText: 'Scan hoặc Nhập mã tại đây...',
        border: const OutlineInputBorder(),
        suffixIcon: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan'),
        ),
      ),
    );
  }
}