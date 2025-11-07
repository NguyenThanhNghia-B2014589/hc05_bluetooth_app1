import 'package:flutter/foundation.dart';
import '../../../data/weighing_data.dart';
import '../widgets/hourly_weighing_chart.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DashboardController with ChangeNotifier {
  final String _apiBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3636';
  
  // --- State ---
  List<WeighingRecord> _allRecords = [];
  List<ChartData> _chartData = [];
  double _totalNhap = 0.0;
  double _totalXuat = 0.0;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // --- Getters ---
  List<ChartData> get chartData => _chartData;
  double get totalNhap => _totalNhap;
  double get totalXuat => _totalXuat;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;

  DashboardController() {
    _loadDataFromApi();
  }

  // --- Load data từ API ---
  Future<void> _loadDataFromApi() async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse('$_apiBaseUrl/api/history?days=all');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        List<WeighingRecord> allRecords = [];

        // Duyệt qua từng group
        for (var group in data) {
          // Lấy mảng records bên trong
          final List<dynamic> recordsList = group['records'] ?? [];

          // Parse từng record trong mảng records
          for (var jsonItem in recordsList) {
            try {
              // Kiểm tra mixTime
              if (jsonItem['mixTime'] == null) {
                if (kDebugMode) {
                  print('⚠️ Bỏ qua record không có mixTime');
                }
                continue;
              }

              // Chuyển UTC sang Local Time
              final mixTimeUtc = DateTime.parse(jsonItem['mixTime']);
              final mixTimeLocal = mixTimeUtc.toLocal();

              final record = WeighingRecord(
                maCode: (jsonItem['maCode'] ?? '').toString(),
                ovNO: (jsonItem['ovNO'] ?? '').toString(),
                package: jsonItem['package'] ?? 0,
                mUserID: (jsonItem['MUserID'] ?? jsonItem['mUserID'] ?? '').toString(), // API dùng MUserID (viết hoa)
                qtys: (jsonItem['qtys'] as num? ?? 0.0).toDouble(),
                mixTime: mixTimeLocal,
                realQty: (jsonItem['realQty'] as num? ?? 0.0).toDouble(),
                isSuccess: true,
                loai: (jsonItem['loai'] ?? '').toString(),
                soLo: jsonItem['soLo'] ?? 0,
                tenPhoiKeo: (jsonItem['tenPhoiKeo'] ?? '').toString(),
                soMay: (jsonItem['soMay'] ?? '').toString(),
                nguoiThaoTac: (jsonItem['nguoiThaoTac'] ?? '').toString(),
              );

              allRecords.add(record);

            } catch (e) {
              if (kDebugMode) {
                print('❌ Lỗi parse record: $e');
                print('📦 Record lỗi: $jsonItem');
              }
            }
          }
        }

        _allRecords = allRecords;

        // Tính tổng cho toàn bộ dữ liệu (Pie Chart)
        _calculateTotals();

        // Xử lý data cho ngày được chọn (Bar Chart)
        _processDataForChart(_selectedDate);

      } else {
        if (kDebugMode) {
          print('❌ Lỗi tải data: ${response.statusCode}');
          print('📦 Response body: ${response.body}');
        }
        _resetData();
      }
    } on FormatException catch (e) {
      if (kDebugMode) {
        print('❌ Lỗi format JSON: $e');
      }
      _resetData();
    } on TypeError catch (e) {
      if (kDebugMode) {
        print('❌ Lỗi type casting: $e');
      }
      _resetData();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Lỗi kết nối API: $e');
        print('📍 Stack trace: $stackTrace');
      }
      _resetData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Tính tổng nhập/xuất cho toàn bộ dữ liệu ---
  void _calculateTotals() {
    _totalNhap = 0.0;
    _totalXuat = 0.0;

    for (final record in _allRecords) {
      final amount = record.realQty ?? 0.0;
      if (record.loai == 'nhap') {
        _totalNhap += amount;
      } else if (record.loai == 'xuat') {
        _totalXuat += amount;
      }
    }
  }

  // --- Xử lý data cho Bar Chart theo ngày ---
  void _processDataForChart(DateTime date) {
    // Định nghĩa các ca làm việc (Local Time)
    final ca1Start = DateTime(date.year, date.month, date.day, 6, 0);   // 06:00
    final ca2Start = DateTime(date.year, date.month, date.day, 14, 0);  // 14:00
    final ca3Start = DateTime(date.year, date.month, date.day, 22, 0);  // 22:00
    final nextCa1Start = DateTime(date.year, date.month, date.day + 1, 6, 0); // 06:00 hôm sau

    // Khởi tạo dữ liệu ca
    Map<String, Map<String, double>> shiftData = {
      'Ca 1': {'nhap': 0.0, 'xuat': 0.0},
      'Ca 2': {'nhap': 0.0, 'xuat': 0.0},
      'Ca 3': {'nhap': 0.0, 'xuat': 0.0},
    };

    // Lọc records trong khoảng thời gian từ 06:00 ngày được chọn đến 06:00 ngày hôm sau
    final recordsForDay = _allRecords.where((record) {
      if (record.mixTime == null) return false;
      final thoiGian = record.mixTime!;
      return (thoiGian.isAtSameMomentAs(ca1Start) || thoiGian.isAfter(ca1Start)) &&
             thoiGian.isBefore(nextCa1Start);
    }).toList();

    // Phân loại vào các ca
    for (final record in recordsForDay) {
      final thoiGian = record.mixTime!;
      final amount = record.realQty ?? 0.0;
      final type = (record.loai == 'nhap') ? 'nhap' : 'xuat';

      if (thoiGian.isBefore(ca2Start)) {
        // Ca 1: 06:00 - 13:59
        shiftData['Ca 1']![type] = shiftData['Ca 1']![type]! + amount;
      } else if (thoiGian.isBefore(ca3Start)) {
        // Ca 2: 14:00 - 21:59
        shiftData['Ca 2']![type] = shiftData['Ca 2']![type]! + amount;
      } else {
        // Ca 3: 22:00 - 05:59
        shiftData['Ca 3']![type] = shiftData['Ca 3']![type]! + amount;
      }
    }

    // Tạo chart data
    _chartData = [
      ChartData('Ca 1', shiftData['Ca 1']!['nhap']!, shiftData['Ca 1']!['xuat']!),
      ChartData('Ca 2', shiftData['Ca 2']!['nhap']!, shiftData['Ca 2']!['xuat']!),
      ChartData('Ca 3', shiftData['Ca 3']!['nhap']!, shiftData['Ca 3']!['xuat']!),
    ];

    notifyListeners();
  }

  // --- Cập nhật ngày được chọn ---
  void updateSelectedDate(DateTime newDate) {
    final currentDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final newDateOnly = DateTime(newDate.year, newDate.month, newDate.day);

    if (currentDateOnly != newDateOnly) {
      _selectedDate = newDate;
      _processDataForChart(newDate);
    }
  }

  // --- Refresh data từ API ---
  Future<void> refreshData() async {
    await _loadDataFromApi();
  }

  // --- Reset data ---
  void _resetData() {
    _allRecords = [];
    _totalNhap = 0.0;
    _totalXuat = 0.0;
    _chartData = [
      ChartData('Ca 1', 0.0, 0.0),
      ChartData('Ca 2', 0.0, 0.0),
      ChartData('Ca 3', 0.0, 0.0),
    ];
  }
}