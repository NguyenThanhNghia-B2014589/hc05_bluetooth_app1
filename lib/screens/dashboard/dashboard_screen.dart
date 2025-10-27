import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/bluetooth_service.dart';
import '../../widgets/main_app_bar.dart';
import 'widgets/hourly_weighing_chart.dart';
import '../../data/weighing_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  final TextEditingController _dateController = TextEditingController();

  late List<WeighingRecord> _allRecords; // Tất cả lịch sử
  List<ChartData> _chartData = []; // Dữ liệu đã xử lý cho chart

  DateTime _selectedDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    // Đặt ngày mặc định là hôm nay
   final now = DateTime.now();
  _dateController.text = DateFormat('dd/MM/yyyy').format(now);
    _loadDataFromMock();
    _processDataForChart(now);
  }
  
  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void _loadDataFromMock() {
    DateTime parseMockDate(String dateStr) {
      try {
        final parts = dateStr.split(' ');
        final timeParts = parts[0].split(':');
        final dateParts = parts[1].split('/');
        return DateTime(
          int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]),
          int.parse(timeParts[0]), int.parse(timeParts[1]),
        );
      } catch (e) {
        return DateTime(2000); // Trả về ngày mặc định nếu lỗi
      }
    }

    _allRecords = mockLastWeighingData.entries.map((entry) {
      final data = entry.value;
      return WeighingRecord(
        maCode: entry.key,
        tenPhoiKeo: data['tenPhoiKeo']!,
        soLo: data['soLo']!,
        soMay: data['soMay']!,
        nguoiThaoTac: data['nguoiThaoTac']!,
        thoiGianCan: parseMockDate(data['thoiGianCan']!),
        khoiLuongMe: data['khoiLuongMe']!,
        khoiLuongDaCan: data['khoiLuongSauCan']!,
        loai: data['loai'],
      );
    }).toList();
  }

  void _processDataForChart(DateTime selectedDate) {
    // 1. Khởi tạo map 0 cho các giờ (7h-17h)
    Map<int, Map<String, double>> hourlyData = {};
    for (int i = 7; i <= 17; i++) {
      hourlyData[i] = {'nhap': 0.0, 'xuat': 0.0};
    }

    // 2. Lọc các record theo ngày đã chọn
    final recordsForDay = _allRecords.where((record) {
      if (record.thoiGianCan == null) return false;
      final d = record.thoiGianCan!;
      return d.year == selectedDate.year &&
             d.month == selectedDate.month &&
             d.day == selectedDate.day;
    }).toList();

    // 3. Tổng hợp khối lượng
    for (final record in recordsForDay) {
      int hour = record.thoiGianCan!.hour;
      if (hourlyData.containsKey(hour)) {
        final amount = record.khoiLuongDaCan ?? 0.0;
        
        if (record.loai == 'nhap') {
          hourlyData[hour]!['nhap'] = hourlyData[hour]!['nhap']! + amount;
        } else if (record.loai == 'xuat') {
          hourlyData[hour]!['xuat'] = hourlyData[hour]!['xuat']! + amount;
        }
      }
    }
    
    // 4. Chuyển Map thành List<ChartData> và cập nhật UI
    setState(() {
      _chartData = hourlyData.entries.map((entry) {
        // entry.key = giờ (7, 8, 9...)
        // entry.value = {'nhap': 1800, 'xuat': 0}
        return ChartData(entry.key, entry.value['nhap']!, entry.value['xuat']!);
      }).toList();
    });
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
                child: HourlyWeighingChart(data: _chartData), // <-- Truyền data vào
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
      width: 250, // Giữ độ rộng
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        // border: Border.all(color: Colors.grey[400]!), // <-- XÓA BORDER
      ),
      child: TextField(
        controller: _dateController,
        readOnly: true,
        style: const TextStyle(fontSize: 20),
        decoration: InputDecoration( // Bỏ 'const'
          border: InputBorder.none,
          
          // --- THAY THẾ SUFFIXICON BẰNG ROW NÀY ---
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min, // Giúp Row co lại
            children: [
              // 1. Nút Lịch
              IconButton(
                icon: const Icon(Icons.calendar_today, size: 18),
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked; // Cập nhật state
                    });
                    _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
                    _processDataForChart(picked);
                  }
                },
              ),
              
              // 2. Nút Xóa (Reset về hôm nay)
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  final today = DateTime.now();
                  setState(() {
                    _selectedDate = today; // Cập nhật state
                  });
                  _dateController.text = DateFormat('dd/MM/yyyy').format(today);
                  _processDataForChart(today);
                },
              ),
            ],
          )
        ),
      ),
    );
  }
}