import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';
import '../services/notification_service.dart';

class WeighingRecord {
  final String tenPhoiKeo;
  final String soLo;
  final String soMay;
  final double khoiLuongMe;
  final String nguoiThaoTac;
  final DateTime thoiGianCan;

  WeighingRecord({
    required this.tenPhoiKeo,
    required this.soLo,
    required this.soMay,
    required this.khoiLuongMe,
    required this.nguoiThaoTac,
    required this.thoiGianCan,
  });
}

class WeighingStationScreen extends StatefulWidget {
  const WeighingStationScreen({super.key});

  @override
  State<WeighingStationScreen> createState() => _WeighingStationScreenState();
}

class _WeighingStationScreenState extends State<WeighingStationScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  final List<WeighingRecord> _records = []; // Danh sách lưu trữ các bản ghi cân

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
  // Widget hiển thị bảng cân
  Widget _buildWeighingTable() {
  const headerStyle = TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  const cellStyle = TextStyle(fontSize: 14);

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.black12.withValues(alpha: 0.15),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Column(
        children: [
          // HEADER
          Container(
            color: const Color(0xFF40B9FF), // màu xanh header
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Expanded(
                    flex: 2,
                    child: Center(child: Text('Tên Phôi Keo', style: headerStyle))),
                Expanded(
                    flex: 1, child: Center(child: Text('Số Lô', style: headerStyle))),
                Expanded(
                    flex: 1, child: Center(child: Text('Số Máy', style: headerStyle))),
                Expanded(
                    flex: 2,
                    child:
                        Center(child: Text('Khối Lượng Mẻ (kg)', style: headerStyle))),
                Expanded(
                    flex: 2,
                    child: Center(child: Text('Người Thao Tác', style: headerStyle))),
                Expanded(
                    flex: 2,
                    child: Center(child: Text('Thời Gian Cân', style: headerStyle))),
              ],
            ),
          ),

          // DỮ LIỆU HOẶC THÔNG BÁO TRỐNG
          if (_records.isEmpty)
            Container(
              width: double.infinity,
              color: const Color(0xFFF7F7F7),
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: const Center(
                child: Text(
                  'Vui lòng quét mã để hiển thị thông tin',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...List.generate(_records.length, (index) {
              final record = _records[index];
              final isEven = index % 2 == 0;
              return Container(
                color: isEven ? Colors.white : const Color(0xFFF7F7F7),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                        flex: 2,
                        child: Center(
                            child: Text(record.tenPhoiKeo, style: cellStyle))),
                    Expanded(
                        flex: 1,
                        child:
                            Center(child: Text(record.soLo, style: cellStyle))),
                    Expanded(
                        flex: 1,
                        child:
                            Center(child: Text(record.soMay, style: cellStyle))),
                    Expanded(
                        flex: 2,
                        child: Center(
                            child: Text(
                                record.khoiLuongMe.toStringAsFixed(1),
                                style: cellStyle))),
                    Expanded(
                        flex: 2,
                        child: Center(
                            child: Text(record.nguoiThaoTac,
                                style: cellStyle))),
                    Expanded(
                        flex: 2,
                        child: Center(
                            child: Text(
                              '${record.thoiGianCan.hour.toString().padLeft(2, '0')}:${record.thoiGianCan.minute.toString().padLeft(2, '0')}',
                              style: cellStyle,
                            ))),
                  ],
                ),
              );
            }),
        ],
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LƯU TRÌNH CÂN KEO XƯỞNG ĐẾ'),
        // Tự động ẩn nút quay lại vì chúng ta đã xử lý logic chuyển màn hình
        automaticallyImplyLeading: false, 
        actions: [
          // Widget hiển thị tên thiết bị
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.person),
                const SizedBox(width: 8),
                Text(_bluetoothService.connectedDevice.value?.name ?? 'HC-05'),
              ],
            )
          ),
          
          // --- NÚT NGẮT KẾT NỐI ---
          IconButton(
            icon: const Icon(Icons.link_off), // Icon ngắt kết nối
            tooltip: 'Ngắt kết nối', // Chú thích khi giữ chuột lâu
            onPressed: () {
              // Gọi hàm disconnect từ BluetoothService
              _bluetoothService.disconnect();
            },
          ),
          const SizedBox(width: 8), // Thêm một chút khoảng cách
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

  // Giao diện cho điện thoại
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
  
  // Giao diện cho tablet
   Widget _buildWideLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
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
            child: ElevatedButton(
              onPressed: () {
                // WIDGET THÔNG BÁO
                NotificationService().showToast(
                  context: context,
                  message: 'Cân thành công!',
                  type: ToastType.success,
                );
              },
              child: const Text('Hoàn tất'),
            ),
          ),
          const SizedBox(height: 24),
          _buildWeighingTable(), // Gọi bảng cân
          const SizedBox(height: 50), 
          _buildScanInput(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Widget hiển thị trọng lượng hiện tại
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                ValueListenableBuilder<double>(
                  valueListenable: _bluetoothService.currentWeight,
                  builder: (context, weight, child) {
                    return Text(
                      weight.toStringAsFixed(3),
                      style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
                    );
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  'kg',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // --- XÓA BỎ WIDGET NÀY ---
            // const TextField(
            //   decoration: InputDecoration(
            //     labelText: 'Nhập cân nặng', border: OutlineInputBorder(),
            //   ),
            //   keyboardType: TextInputType.number,
            // ),
            
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
        _buildInfoCard('TIÊU CHUẨN', '0.0 kg'),
        _buildInfoCard('% TỐI ĐA', '3%'),
        _buildInfoCard('MIN', '0.0 kg'),
        _buildInfoCard('MAX', '0.0 kg'),
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
  
  // Widget input quét mã
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