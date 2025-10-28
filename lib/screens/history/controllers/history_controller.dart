import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/weighing_data.dart'; // Import model và mock data

class HistoryController with ChangeNotifier {
  // --- Controllers cho UI ---
  final TextEditingController dateController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  // --- State quản lý dữ liệu ---
  List<WeighingRecord> _allRecords = [];
  List<WeighingRecord> _filteredRecords = [];
  List<WeighingRecord> get filteredRecords => _filteredRecords; // Getter cho UI

  // --- State quản lý Filter ---
  String _selectedFilterType = 'Tên phôi keo';
  String get selectedFilterType => _selectedFilterType;

  DateTime? _selectedDate;
  DateTime? get selectedDate => _selectedDate;

  String _searchText = '';
  String get searchText => _searchText;

  HistoryController() {
    _loadData(); // Tải data khi controller được tạo
    // Thêm listener cho ô tìm kiếm
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

  // --- Logic tải dữ liệu (từ HistoryScreen cũ) ---
  void _loadData() {
    DateTime parseMockDate(String dateStr) {
      try {
        final parts = dateStr.split(' ');
        final timeParts = parts[0].split(':');
        final dateParts = parts[1].split('/');
        return DateTime(
          int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]),
          int.parse(timeParts[0]), int.parse(timeParts[1]),
        );
      } catch (e) { return DateTime(2000); }
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
        loai: data['loai'],
      );
    }).toList();
    _allRecords.sort((a, b) {
      // Sắp xếp giảm dần (descending) theo thời gian cân
      // (Giả sử thoiGianCan không bao giờ null trong mock lịch sử)
      return b.thoiGianCan!.compareTo(a.thoiGianCan!);
    });

    _filteredRecords = _allRecords; // Ban đầu hiển thị tất cả
    notifyListeners(); // Thông báo cho UI cập nhật
  }

  // --- Logic Filter (từ HistoryScreen cũ) ---
  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _runFilter() {
    List<WeighingRecord> results = _allRecords;

    // Lọc theo Ngày
    if (_selectedDate != null) {
      results = results
          .where((record) => _isSameDay(record.thoiGianCan, _selectedDate))
          .toList();
    }

    // Lọc theo Từ khóa
    if (_searchText.isNotEmpty) {
      String query = _searchText.toLowerCase();
      results = results.where((record) {
        if (_selectedFilterType == 'Tên phôi keo') {
          return record.tenPhoiKeo.toLowerCase().contains(query);
        } else if (_selectedFilterType == 'Mã code') {
          return record.maCode.toLowerCase().contains(query);
        }
        return false;
      }).toList();
    }

    _filteredRecords = results;
    notifyListeners(); // Thông báo cho UI cập nhật
  }

  // --- Hàm cập nhật state từ UI ---
  void updateFilterType(String? newType) {
    if (newType != null && _selectedFilterType != newType) {
      _selectedFilterType = newType;
      _runFilter(); // Lọc lại với type mới
    }
  }

  void updateSelectedDate(DateTime newDate) {
    if (_selectedDate != newDate) {
      _selectedDate = newDate;
      dateController.text = DateFormat('dd/MM/yyyy').format(newDate);
      _runFilter(); // Lọc lại với ngày mới
    }
  }

  void clearSelectedDate() {
    if (_selectedDate != null) {
      _selectedDate = null;
      dateController.clear();
      _runFilter(); // Lọc lại khi bỏ ngày
    }
  }
}