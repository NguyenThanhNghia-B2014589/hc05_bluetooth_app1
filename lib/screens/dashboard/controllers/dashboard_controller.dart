import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart'; // Cần cho việc format ngày

import '../widgets/hourly_weighing_chart.dart'; // Import ChartData

class DashboardController with ChangeNotifier {
  final String _apiBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3636';
  
  // --- State ---
  // (Xóa _allRecords vì không cần nữa)
  List<ChartData> _chartData = []; // Data cho Bar Chart
  double _totalNhap = 0.0; // Data cho Pie Chart
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
    // 1. Tải dữ liệu cho cả 2 biểu đồ
    _loadAllDashboardData();
  }

  // --- HÀM MỚI: Tải tất cả ---
  Future<void> _loadAllDashboardData() async {
    _isLoading = true;
    notifyListeners();

    // Chạy song song 2 API
    await Future.wait([
      _loadInventorySummary(), // Tải data cho Pie Chart
      _processDataForChart(_selectedDate), // Tải data cho Bar Chart (với ngày mặc định)
    ]);

    _isLoading = false;
    notifyListeners();
  }

  // --- 1. SỬA HÀM TẢI DATA BIỂU ĐỒ TRÒN ---
  Future<void> _loadInventorySummary() async {
    try {
      final url = Uri.parse('$_apiBaseUrl/api/dashboard/inventory-summary');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Đọc từ JSON 'summary' mới
        final summary = data['summary'];
        _totalNhap = (summary['totalNhap'] as num? ?? 0.0).toDouble();
        _totalXuat = (summary['totalXuat'] as num? ?? 0.0).toDouble();
        // (Chúng ta có thể lưu 'byGlueType' ở đây nếu cần)

      } else {
        if (kDebugMode) print('Lỗi tải Pie Chart: ${response.statusCode}');
        _totalNhap = 0.0;
        _totalXuat = 0.0;
      }
    } catch (e) {
      if (kDebugMode) print('Lỗi mạng Pie Chart: $e');
      _totalNhap = 0.0;
      _totalXuat = 0.0;
    }
    // (Không cần notifyListeners() vội, để hàm _loadAllDashboardData làm)
  }
  // --- KẾT THÚC SỬA ---

  // --- 2. SỬA HÀM TẢI DATA BIỂU ĐỒ CỘT ---
  Future<void> _processDataForChart(DateTime date) async {
    try {
      // Format ngày thành 'YYYY-MM-DD'
      final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      
      // Gọi API mới
      final url = Uri.parse('$_apiBaseUrl/api/dashboard/shift-weighing?date=$formattedDate');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Map dữ liệu JSON mới
        _chartData = data.map((item) {
          return ChartData(
            item['Ca'] as String, // "Ca 1"
            (item['KhoiLuongNhap'] as num? ?? 0.0).toDouble(),
            (item['KhoiLuongXuat'] as num? ?? 0.0).toDouble(),
          );
        }).toList();

      } else {
        if (kDebugMode) print('Lỗi tải Bar Chart: ${response.statusCode}');
        _resetBarChartData();
      }
    } catch (e) {
      if (kDebugMode) print('Lỗi mạng Bar Chart: $e');
      _resetBarChartData();
    }
    // (Không cần notifyListeners() vội, để hàm _loadAllDashboardData làm)
  }
  // --- KẾT THÚC SỬA ---

  // --- 3. SỬA HÀM CẬP NHẬT NGÀY ---
  void updateSelectedDate(DateTime newDate) async {
    final currentDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final newDateOnly = DateTime(newDate.year, newDate.month, newDate.day);

    if (currentDateOnly != newDateOnly) {
      _selectedDate = newDate;
      _isLoading = true;
      notifyListeners(); // Hiển thị loading

      await _processDataForChart(newDate); // Chỉ tải lại Bar Chart
      
      _isLoading = false;
      notifyListeners(); // Cập nhật Bar Chart mới
    }
  }

  // --- 4. THÊM HÀM REFRESH (GỌI TỪ UI NẾU CẦN) ---
  Future<void> refreshData() async {
    await _loadAllDashboardData();
  }

  // --- 5. THÊM HÀM RESET (ĐỂ DÙNG KHI LỖI) ---
  void _resetBarChartData() {
    _chartData = [
      ChartData('Ca 1', 0.0, 0.0),
      ChartData('Ca 2', 0.0, 0.0),
      ChartData('Ca 3', 0.0, 0.0),
    ];
  }
}