import 'package:flutter/material.dart';
import '../../../data/weighing_data.dart';
import '../widgets/hourly_weighing_chart.dart'; // Import ChartData

class DashboardController with ChangeNotifier {
  // --- State ---
  List<WeighingRecord> _allRecords = [];
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
    _loadDataFromMock(); // Load totals for Pie Chart
    _processDataForChart(_selectedDate); // Process data for Bar Chart for the initial date
  }

  // --- Logic Functions (Moved from DashboardScreen) ---

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
      _totalNhap = dayNhap;
      _totalXuat = dayXuat;
    
  }

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

      final recordsForDay = _allRecords.where((record) {
         if (record.thoiGianCan == null) return false;
         final thoiGian = record.thoiGianCan!;
         return (thoiGian.isAtSameMomentAs(ca1Start) || thoiGian.isAfter(ca1Start)) &&
                thoiGian.isBefore(endOfDay);
      }).toList();

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

      _chartData = [
        ChartData('Ca 1', shiftData['Ca 1']!['nhap']!, shiftData['Ca 1']!['xuat']!),
        ChartData('Ca 2', shiftData['Ca 2']!['nhap']!, shiftData['Ca 2']!['xuat']!),
        ChartData('Ca 3', shiftData['Ca 3']!['nhap']!, shiftData['Ca 3']!['xuat']!),
      ];
      notifyListeners(); // Notify UI to update Bar Chart
  }

  // --- Method called by UI when date changes ---
  void updateSelectedDate(DateTime newDate) {
    if (_selectedDate != newDate) {
      _selectedDate = newDate;
      _processDataForChart(newDate); // Re-process data for the Bar Chart
      // No need to call notifyListeners here as _processDataForChart already does
    }
  }
}