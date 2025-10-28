import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/bluetooth_service.dart';
import '../../widgets/main_app_bar.dart';
import 'widgets/hourly_weighing_chart.dart';
import '../../data/weighing_data.dart';
import 'widgets/inventory_pie_chart.dart';
import '../../widgets/date_picker_input.dart';

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

  double _totalNhap = 0.0;
  double _totalXuat = 0.0;
  
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
    double dayNhap = 0.0;
    double dayXuat = 0.0;

    for (final record in _allRecords) { // Duyệt qua TẤT CẢ record
      final amount = record.khoiLuongDaCan ?? 0.0;
      if (record.loai == 'nhap') {
        dayNhap += amount;
      } else if (record.loai == 'xuat') {
        dayXuat += amount;
      }
    }
    
    // 2. Cập nhật state cho Biểu đồ tròn (chỉ 1 lần)
    setState(() {
      _totalNhap = dayNhap;
      _totalXuat = dayXuat;
    });
  }

  void _processDataForChart(DateTime selectedDate) {

  // 1. Định nghĩa 3 ca
  // (selectedDate ví dụ là 16/08)
  final ca1Start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 6, 0); // 06:00 16/08
  final ca2Start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 14, 0); // 14:00 16/08
  final ca3Start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 22, 0); // 22:00 16/08
  final endOfDay = ca1Start.add(const Duration(days: 1)); // 06:00 17/08

  // 2. Khởi tạo map cho 3 ca
  Map<String, Map<String, double>> shiftData = {
    'Ca 1': {'nhap': 0.0, 'xuat': 0.0},
    'Ca 2': {'nhap': 0.0, 'xuat': 0.0},
    'Ca 3': {'nhap': 0.0, 'xuat': 0.0},
  };

  // 3. Lọc các record trong 24h (từ 6h hôm nay đến 6h hôm sau)
  final recordsForDay = _allRecords.where((record) {
    if (record.thoiGianCan == null) return false;
    final thoiGian = record.thoiGianCan!;

    // Nằm trong khoảng (>= 06:00 hôm nay) VÀ (< 06:00 hôm sau)
    return (thoiGian.isAtSameMomentAs(ca1Start) || thoiGian.isAfter(ca1Start)) &&
           thoiGian.isBefore(endOfDay);
  }).toList();

  // 4. Tổng hợp khối lượng theo ca
  for (final record in recordsForDay) {
    final thoiGian = record.thoiGianCan!;
    final amount = record.khoiLuongDaCan ?? 0.0;
    final type = (record.loai == 'nhap') ? 'nhap' : 'xuat';

    // So sánh thời gian để xếp vào ca
    if (thoiGian.isBefore(ca2Start)) {
      // Từ 06:00 -> 13:59
      shiftData['Ca 1']![type] = shiftData['Ca 1']![type]! + amount;
    } else if (thoiGian.isBefore(ca3Start)) {
      // Từ 14:00 -> 21:59
      shiftData['Ca 2']![type] = shiftData['Ca 2']![type]! + amount;
    } else {
      // Từ 22:00 -> 05:59 (hôm sau)
      shiftData['Ca 3']![type] = shiftData['Ca 3']![type]! + amount;
    }
  }

  // 5. Cập nhật UI
  setState(() {
    _chartData = [
      ChartData('Ca 1', shiftData['Ca 1']!['nhap']!, shiftData['Ca 1']!['xuat']!),
      ChartData('Ca 2', shiftData['Ca 2']!['nhap']!, shiftData['Ca 2']!['xuat']!),
      ChartData('Ca 3', shiftData['Ca 3']!['nhap']!, shiftData['Ca 3']!['xuat']!),
    ];
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 3. Header (Title và Date Picker)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DashBoard - Tổng Quan',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                DatePickerInput(
                  selectedDate: _selectedDate,
                  controller: _dateController,
                  onDateSelected: (newDate) {
                    // Logic xử lý khi ngày thay đổi (đã có)
                    setState(() {
                      _selectedDate = newDate;
                    });
                    _dateController.text = DateFormat('dd/MM/yyyy').format(newDate);
                    _processDataForChart(newDate);
                  },
                  onDateCleared: () {
                    // Ở Dashboard, "Xóa" có nghĩa là "Reset về hôm nay"
                    final today = DateTime.now();
                    setState(() {
                      _selectedDate = today;
                    });
                    _dateController.text = DateFormat('dd/MM/yyyy').format(today);
                    _processDataForChart(today);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // 4. Biểu đồ
            Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CỘT 1: BIỂU ĐỒ CỘT (Đã có)
                Expanded(
                  flex: 3, // Biểu đồ cột chiếm 3 phần
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                          children: [
                            // Lớp 1: Biểu đồ
                            HourlyWeighingChart(data: _chartData),
                          ],
                        ),
                  ),
                ),

                const SizedBox(width: 24), // Khoảng cách

                // CỘT 2: BIỂU ĐỒ TRÒN (Mới)
                Expanded(
                  flex: 2, // Biểu đồ tròn chiếm 2 phần
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    // Truyền 2 giá trị tổng vào
                    child: InventoryPieChart(
                      totalNhap: _totalNhap, 
                      totalXuat: _totalXuat,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}