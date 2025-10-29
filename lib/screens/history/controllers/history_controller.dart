import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/weighing_data.dart'; // Import data mới

class HistoryController with ChangeNotifier {
  // --- Controllers cho UI ---
  final TextEditingController dateController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  // --- Dữ liệu Mock (giờ lấy từ weighing_data.dart) ---
  final Map<String, Map<String, dynamic>> _workLSData = mockWorkLSData;
  final Map<String, Map<String, dynamic>> _workData = mockWorkData;
  final Map<int, Map<String, dynamic>> _persionalData = mockPersionalData;

  // --- State quản lý dữ liệu ---
  List<WeighingRecord> _allRecords = []; // Danh sách đầy đủ (đã xử lý)
  List<WeighingRecord> _filteredRecords = [];
  List<WeighingRecord> get filteredRecords => _filteredRecords;

  // --- State quản lý Filter ---
  String _selectedFilterType = 'Tên phôi keo';
  String get selectedFilterType => _selectedFilterType;
  DateTime? _selectedDate;
  DateTime? get selectedDate => _selectedDate;
  String _searchText = '';
  String get searchText => _searchText;

  HistoryController() {
    _loadData(); // Tải data khi controller được tạo
    searchController.addListener(() {
      if (_searchText != searchController.text) {
        _searchText = searchController.text;
        _runFilter();
      }
    });
  }

  @override
  void dispose() {
    dateController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // --- THAY THẾ TOÀN BỘ HÀM _loadData ---
  void _loadData() {
    _allRecords = []; // Xóa list cũ

    // Duyệt qua dữ liệu _VML_WorkLS
    _workLSData.forEach((maCode, workLSItem) {
      // Chỉ lấy các bản ghi đã hoàn tất (có MixTime)
      final dynamic mixTimeValue = workLSItem['MixTime'];
      final DateTime? mixTime = parseMixTime(mixTimeValue); // Dùng hàm helper

      if (mixTime != null) {
        // Lấy thông tin cơ bản từ WorkLS
        final String ovNO = workLSItem['OVNO'];
        final int package = workLSItem['package'];
        final int mUserID = workLSItem['MUserID'];
        final double qtyValue = workLSItem['Qty']; // Mẻ/Tồn
        final double? realQtyValue = workLSItem['RKQty']; // Đã cân
        final String? loaiValue = workLSItem['loai']; // Loại (từ mock data mới)

        // Tra cứu thông tin bổ sung
        final workItem = _workData[ovNO];
        final persionalItem = _persionalData[mUserID];

        final String tenPhoiKeo = workItem?['FormulaF'] ?? 'Không rõ';
        final String soMay = workItem?['soMay'] ?? 'N/A';
        final String nguoiThaoTac = persionalItem?['UerName'] ?? 'Không rõ';

        

        // Tạo đối tượng WeighingRecord hoàn chỉnh
        _allRecords.add(WeighingRecord(
          maCode: maCode,
          ovNO: ovNO,
          package: package,
          mUserID: mUserID,
          qty: qtyValue,
          mixTime: mixTime, // Thời gian cân
          realQty: realQtyValue, // Khối lượng đã cân
          isSuccess: true, // Lịch sử mặc định là thành công
          loai: loaiValue, // Loại cân
          // Thông tin bổ sung
          tenPhoiKeo: tenPhoiKeo,
          soMay: soMay,
          nguoiThaoTac: nguoiThaoTac,
          soLo: package,
        ));
      }
    });

    // Sắp xếp theo thời gian mới nhất lên trước
    _allRecords.sort((a, b) => b.mixTime!.compareTo(a.mixTime!));

    _filteredRecords = _allRecords; // Ban đầu hiển thị tất cả
    notifyListeners();
  }

  // --- Logic Filter (giữ nguyên) ---
  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _runFilter() {
    List<WeighingRecord> results = _allRecords;

    if (_selectedDate != null) {
      results = results
          .where((record) => _isSameDay(record.mixTime, _selectedDate)) // Sửa thành mixTime
          .toList();
    }

    if (_searchText.isNotEmpty) {
      String query = _searchText.toLowerCase();
      results = results.where((record) {
        // Thêm tìm kiếm theo Số Lô nếu muốn
        //final bool matchSoLo = record.soLo?.toLowerCase().contains(query) ?? false;

        if (_selectedFilterType == 'Tên phôi keo') {
          return record.tenPhoiKeo?.toLowerCase().contains(query) ?? false;
        } else if (_selectedFilterType == 'Mã code') {
          return record.maCode.toLowerCase().contains(query);
        }
        // Thêm tìm kiếm chung (nếu cần bỏ comment)
        // return (record.tenPhoiKeo?.toLowerCase().contains(query) ?? false) ||
        //        record.maCode.toLowerCase().contains(query) ||
        //        matchSoLo;
        return false;
      }).toList();
    }

    _filteredRecords = results;
    notifyListeners();
  }

  // --- Các hàm cập nhật state từ UI (giữ nguyên) ---
  void updateFilterType(String? newType) {
    if (newType != null && _selectedFilterType != newType) {
      _selectedFilterType = newType;
      _runFilter();
    }
  }

  void updateSelectedDate(DateTime newDate) {
    if (_selectedDate != newDate) {
      _selectedDate = newDate;
      dateController.text = DateFormat('dd/MM/yyyy').format(newDate);
      _runFilter();
    }
  }

  void clearSelectedDate() {
    if (_selectedDate != null) {
      _selectedDate = null;
      dateController.clear();
      _runFilter();
    }
  }
}