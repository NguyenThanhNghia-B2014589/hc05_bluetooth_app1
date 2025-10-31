import 'package:flutter/foundation.dart';
//import 'package:flutter/material.dart';
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
    _allRecords = []; // Clear the old list
    double dayNhap = 0.0;
    double dayXuat = 0.0;

    // Iterate through the HISTORY data
    mockHistoryData.forEach((historyKey, historyItem) {
      // Get core info from History
      final String maCode = historyItem['maCode'];
      final String mixTimeString = historyItem['MixTime'];
      final double? realQtyValue = historyItem['khoiLuongSauCan']; // Actual weighed amount from history
      final String? loaiValue = historyItem['loai'];

      final DateTime? mixTime = parseMixTime(mixTimeString); // Use the helper

      // Skip if time is invalid
      if (mixTime == null) return;

      // --- Look up additional info ---
      // 1. Find in WorkLS using maCode to get OVNO, package, MUserID, Qty (Target/Stock)
      final workLSItem = _workLSData[maCode];
      if (workLSItem == null) {
        if (kDebugMode) {
          print('Dashboard Warning: Cannot find code $maCode in mockWorkLSData.');
        }
        // If we still want to show the history entry even if the original LS is gone:
        // Create a record with available data, marking others as unknown.
        _allRecords.add(WeighingRecord(
            maCode: maCode, ovNO: 'N/A', package: 0, mUserID: 'N/A',
            qtys: 0.0, // Target/Stock unknown
            mixTime: mixTime, realQty: realQtyValue, isSuccess: true,
            loai: loaiValue, soLo: 0, tenPhoiKeo: 'N/A', soMay: 'N/A', nguoiThaoTac: 'N/A',
        ));
      } else {
        // Found the original WorkLS entry, proceed to get full details
        final String ovNO = workLSItem['OVNO'];
        final int package = workLSItem['package'];
        final String mUserID = workLSItem['MUserID'].toString();
        final double qtyValue = workLSItem['Qty']; // Target/Stock Qty from WorkLS

        // 2. Find in Work using OVNO
        final workItem = _workData[ovNO];
        final String tenPhoiKeo = workItem?['FormulaF'] ?? 'Không rõ';
        final String soMay = workItem?['soMay'] ?? 'N/A';

        // 3. Find in Persional using MUserID
        final persionalItem = _persionalData[int.tryParse(mUserID)];
        final String nguoiThaoTac = persionalItem?['UerName'] ?? 'Không rõ';

        // Create the complete WeighingRecord object
        _allRecords.add(WeighingRecord(
          maCode: maCode,
          ovNO: ovNO,
          package: package,
          mUserID: mUserID,
          qtys: qtyValue, // Target/Stock Qty
          mixTime: mixTime, // Actual weigh time from History
          realQty: realQtyValue, // Actual weigh amount from History
          isSuccess: true, // History is assumed successful
          loai: loaiValue, // Type from History
          soLo: package, // Package as Batch No.
          // Additional looked-up info
          tenPhoiKeo: tenPhoiKeo,
          soMay: soMay,
          nguoiThaoTac: nguoiThaoTac,
        ));
      }

      // --- Calculate totals for Pie Chart using history data ---
      final amount = realQtyValue ?? 0.0; // Use the actual weighed amount
      if (loaiValue == 'nhap') {
        dayNhap += amount;
      } else if (loaiValue == 'xuat') {
        dayXuat += amount;
      }
    });

    // Cập nhật state cho Pie Chart
    _totalNhap = dayNhap;
    _totalXuat = dayXuat;
    // Không cần notifyListeners ở đây
  }

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