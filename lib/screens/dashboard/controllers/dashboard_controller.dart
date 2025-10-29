import 'package:flutter/material.dart';
import '../../../data/weighing_data.dart'; // Import data mới
import '../widgets/hourly_weighing_chart.dart'; // Import ChartData

class DashboardController with ChangeNotifier {
  // --- Dữ liệu Mock ---
  final Map<String, Map<String, dynamic>> _workLSData = mockWorkLSData;
  final Map<String, Map<String, dynamic>> _workData = mockWorkData;
  final Map<int, Map<String, dynamic>> _persionalData = mockPersionalData;

  // --- State ---
  List<WeighingRecord> _allRecords = []; // Danh sách đầy đủ (đã xử lý)
  List<ChartData> _chartData = []; // Data for Bar Chart
  double _totalNhap = 0.0; // Data for Pie Chart
  double _totalXuat = 0.0;
  DateTime _selectedDate = DateTime.now(); // Default date with mock data

  // --- Getters for UI ---
  List<ChartData> get chartData => _chartData;
  double get totalNhap => _totalNhap;
  double get totalXuat => _totalXuat;
  DateTime get selectedDate => _selectedDate;

  DashboardController() {
    _loadDataFromMock(); // Tải và tính tổng (Pie Chart)
    _processDataForChart(_selectedDate); // Xử lý data ban đầu (Bar Chart)
  }

  // --- THAY THẾ HÀM _loadDataFromMock ---
  void _loadDataFromMock() {
    _allRecords = []; // Xóa list cũ
    double dayNhap = 0.0;
    double dayXuat = 0.0;

    _workLSData.forEach((maCode, workLSItem) {
      final dynamic mixTimeValue = workLSItem['MixTime'];
      final DateTime? mixTime = parseMixTime(mixTimeValue); // Dùng hàm helper

      // Chỉ xử lý các bản ghi đã hoàn tất (có MixTime)
      if (mixTime != null) {
        final String ovNO = workLSItem['OVNO'];
        final int package = workLSItem['package'];
        final int mUserID = workLSItem['MUserID'];
        final double qtyValue = workLSItem['Qty'];
        final double? realQtyValue = workLSItem['RKQty'];
        final String? loaiValue = workLSItem['loai'];

        // Tra cứu
        final workItem = _workData[ovNO];
        final persionalItem = _persionalData[mUserID];
        final String tenPhoiKeo = workItem?['FormulaF'] ?? 'Không rõ';
        final String soMay = workItem?['soMay'] ?? 'N/A';
        final String nguoiThaoTac = persionalItem?['UerName'] ?? 'Không rõ';

        // Tạo Record
        final record = WeighingRecord(
          maCode: maCode, ovNO: ovNO, package: package, mUserID: mUserID,
          qty: qtyValue, mixTime: mixTime, realQty: realQtyValue,
          isSuccess: true, loai: loaiValue, tenPhoiKeo: tenPhoiKeo,
          soMay: soMay, nguoiThaoTac: nguoiThaoTac, soLo: package, // Gán package vào soLo
        );
        _allRecords.add(record);

        // Tính tổng cho Pie Chart
        final amount = record.realQty ?? 0.0; // Dùng realQty (đã cân)
        if (record.loai == 'nhap') {
          dayNhap += amount;
        } else if (record.loai == 'xuat') {
          dayXuat += amount;
        }
      }
    });

    // Cập nhật state cho Pie Chart
    _totalNhap = dayNhap;
    _totalXuat = dayXuat;
    // Không cần notifyListeners ở đây
  }
  // --- KẾT THÚC THAY THẾ ---

  // --- Hàm _processDataForChart (giữ nguyên logic, chỉ cần kiểm tra tên trường) ---
  void _processDataForChart(DateTime date) {
      final ca1Start = DateTime(date.year, date.month, date.day, 6, 0);
      final ca2Start = DateTime(date.year, date.month, date.day, 14, 0);
      final ca3Start = DateTime(date.year, date.month, date.day, 22, 0);
      final endOfDay = ca1Start.add(const Duration(days: 1));

      Map<String, Map<String, double>> shiftData = {
        'Ca 1': {'nhap': 0.0, 'xuat': 0.0}, 
        'Ca 2': {'nhap': 0.0, 'xuat': 0.0},
        'Ca 3': {'nhap': 0.0, 'xuat': 0.0},
      };

      // Dùng _allRecords đã được load sẵn
      final recordsForDay = _allRecords.where((record) {
         if (record.mixTime == null) return false; // Dùng mixTime
         final thoiGian = record.mixTime!;
         return (thoiGian.isAtSameMomentAs(ca1Start) || thoiGian.isAfter(ca1Start)) &&
                thoiGian.isBefore(endOfDay);
      }).toList();

      for (final record in recordsForDay) {
        final thoiGian = record.mixTime!;
        final amount = record.realQty ?? 0.0; // Dùng realQty (đã cân)
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

      _chartData = [
        ChartData('Ca 1', shiftData['Ca 1']!['nhap']!, shiftData['Ca 1']!['xuat']!),
        ChartData('Ca 2', shiftData['Ca 2']!['nhap']!, shiftData['Ca 2']!['xuat']!),
        ChartData('Ca 3', shiftData['Ca 3']!['nhap']!, shiftData['Ca 3']!['xuat']!),
      ];
      notifyListeners(); // Cập nhật Bar Chart
  }

  // --- Hàm updateSelectedDate (giữ nguyên) ---
  void updateSelectedDate(DateTime newDate) {
    // Chỉ cập nhật và xử lý lại nếu ngày thay đổi
    // và ngày mới khác ngày hiện tại (đã làm tròn về ngày)
    final currentDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final newDateOnly = DateTime(newDate.year, newDate.month, newDate.day);

    if (currentDateOnly != newDateOnly) {
      _selectedDate = newDate;
      _processDataForChart(newDate); // Chỉ xử lý lại Bar Chart
    }
  }
}