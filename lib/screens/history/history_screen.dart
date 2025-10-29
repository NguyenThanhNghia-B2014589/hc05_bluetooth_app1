import 'package:flutter/material.dart';
import '../../services/bluetooth_service.dart';
import '../../widgets/main_app_bar.dart';
import 'widgets/history_table.dart';
import '../../widgets/date_picker_input.dart';
import 'controllers/history_controller.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  
  // --- Tạo Controller ---
  late final HistoryController _controller;

  @override
  void initState() {
    super.initState();
    // --- KHỞI TẠO CONTROLLER ---
    _controller = HistoryController();
  }

  @override
  void dispose() {
    // --- HỦY CONTROLLER ---
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        title: 'LƯU TRÌNH CÂN KEO XƯỞNG ĐẾ',
        bluetoothService: _bluetoothService,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Quay lại trang chủ',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      
      body: Container(
        padding: const EdgeInsets.all(24.0),
        // --- DÙNG ANIMATED BUILDER ĐỂ LẮNG NGHE ---
        child: AnimatedBuilder(
          animation: _controller, // Lắng nghe thay đổi từ controller
          builder: (context, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Lịch sử cân',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    _buildFilterBar(), // <-- Gọi hàm _buildFilterBar (sẽ sửa ở dưới)
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  // Lấy data từ controller
                  child: HistoryTable(records: _controller.filteredRecords), 
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- HÀM _buildFilterBar ĐỂ DÙNG CONTROLLER ---
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dropdown Loại Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _controller.selectedFilterType, // <-- Dùng controller
                items: const [
                  DropdownMenuItem(value: 'Tên phôi keo', child: Text('Tên phôi keo')),
                  DropdownMenuItem(value: 'Mã code', child: Text('Mã code')),
                  DropdownMenuItem(value: 'OVNO', child: Text('OVNO')),
                ],
                onChanged: (value) {
                  _controller.updateFilterType(value); // <-- Gọi controller
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Date Picker
          DatePickerInput(
            selectedDate: _controller.selectedDate, // <-- Dùng controller
            controller: _controller.dateController, // <-- Dùng controller
            onDateSelected: (newDate) {
              _controller.updateSelectedDate(newDate); // <-- Gọi controller
            },
            onDateCleared: () {
              _controller.clearSelectedDate(); // <-- Gọi controller
            },
          ),
          
          const VerticalDivider(),
          
          // Search Field
          SizedBox(
            width: 250,
            child: TextField(
              controller: _controller.searchController, // Listener đã được thêm trong initState
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                prefixIcon: Icon(Icons.search),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.black, width: 1.0),
                ),
                
                // 3. Viền khi bấm vào (màu đen, dày hơn)
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.black, width: 2.0),
                ),

                // 4. Căn chỉnh lại padding bên trong ô
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}