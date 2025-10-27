import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/bluetooth_service.dart';
import '../../widgets/main_app_bar.dart';
import 'widgets/hourly_weighing_chart.dart'; // Chart sẽ tạo ở bước 3

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  final TextEditingController _dateController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Đặt ngày mặc định là hôm nay
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
  }
  
  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Tái sử dụng MainAppBar
      appBar: MainAppBar(
        title: 'LƯU TRÌNH CÂN KEO XƯỞNG ĐẾ',
        bluetoothService: _bluetoothService,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Quay lại trang chủ',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      
      // 2. Body
      body: Container(
        color: const Color(0xFFE3F2FD), // Màu nền xanh nhạt
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 3. Header (Title và Date Picker)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng Khối Lượng Theo Giờ',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                _buildDatePicker(context),
              ],
            ),
            const SizedBox(height: 24),
            
            // 4. Biểu đồ
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const HourlyWeighingChart(), // <-- WIDGET BIỂU ĐỒ
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Date Picker
  Widget _buildDatePicker(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: TextField(
        controller: _dateController,
        readOnly: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          suffixIcon: Icon(Icons.calendar_today, size: 20),
        ),
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (picked != null) {
            _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
            // TODO: Thêm logic tải lại dữ liệu chart theo ngày mới
          }
        },
      ),
    );
  }
}