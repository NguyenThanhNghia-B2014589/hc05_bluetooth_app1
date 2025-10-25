import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Cần để format ngày
import '../../data/weighing_data.dart';
import '../../services/bluetooth_service.dart';
import '../../widgets/main_app_bar.dart';
import 'widgets/history_table.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  late List<WeighingRecord> _allRecords; // Danh sách đầy đủ
  List<WeighingRecord> _filteredRecords = []; // Danh sách đã lọc

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Chuyển đổi mock map của bạn thành List<WeighingRecord>
  void _loadData() {
    // Tạm thời dùng hàm parse DateTime (bạn nên dùng thư viện intl cho chuẩn)
    DateTime parseMockDate(String dateStr) {
      // Format: '10:26 16/08/2025'
      try {
        final parts = dateStr.split(' '); // ['10:26', '16/08/2025']
        final timeParts = parts[0].split(':'); // ['10', '26']
        final dateParts = parts[1].split('/'); // ['16', '08', '2025']
        return DateTime(
          int.parse(dateParts[2]), // year
          int.parse(dateParts[1]), // month
          int.parse(dateParts[0]), // day
          int.parse(timeParts[0]), // hour
          int.parse(timeParts[1]), // minute
        );
      } catch (e) {
        return DateTime.now();
      }
    }

    _allRecords = mockLastWeighingData.entries.map((entry) {
      final code = entry.key;
      final data = entry.value;
      return WeighingRecord(
        maCode: code,
        tenPhoiKeo: data['tenPhoiKeo']!,
        soLo: data['soLo']!,
        soMay: data['soMay']!,
        nguoiThaoTac: data['nguoiThaoTac']!,
        thoiGianCan: parseMockDate(data['thoiGianCan']!),
        khoiLuongMe: data['khoiLuongMe']!,
        khoiLuongSauCan: data['khoiLuongSauCan']!,
      );
    }).toList();
    
    _filteredRecords = _allRecords; // Ban đầu hiển thị tất cả
  }
  
  @override
  void dispose() {
    _dateController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // TODO: Thêm logic lọc (search, filter) ở đây

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 3. Title
            const Text(
              'Lịch sử cân',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // 4. Thanh Filter/Search
            _buildFilterBar(),
            
            const SizedBox(height: 16),
            
            // 5. Bảng Dữ Liệu
            Expanded(
              child: HistoryTable(records: _filteredRecords),
            ),
          ],
        ),
      ),
    );
  }

  // Widget xây dựng thanh Filter/Search
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Filter (Tạm thời là Text)
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8)
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: 'Tên phôi keo',
                items: const [
                  DropdownMenuItem(value: 'Tên phôi keo', child: Text('Tên phôi keo')),
                  DropdownMenuItem(value: 'Mã code', child: Text('Mã code')),
                ],
                onChanged: (v) {},
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Date Picker (Tạm thời là TextField)
          SizedBox(
            width: 150,
            child: TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                hintText: 'dd/mm/yyyy',
                suffixIcon: Icon(Icons.calendar_today),
                border: InputBorder.none,
              ),
              onTap: () async {
                // Logic hiện Date Picker
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
                }
              },
            ),
          ),
          const VerticalDivider(),
          // Search Field
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm theo mã, tên, lô...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
              ),
              // onChanged: (value) => _runFilter(value), // Thêm logic filter
            ),
          ),
        ],
      ),
    );
  }
}