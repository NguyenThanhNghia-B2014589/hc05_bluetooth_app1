import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../data/weighing_data.dart'; // Import WeighingRecord
import '../widgets/history_table.dart'; // Import SummaryData

class HistoryController with ChangeNotifier {
  final String _apiBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3636';

  // --- Controllers cho UI ---
  final TextEditingController dateController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  // _allRecords: Danh sách GỐC, chỉ chứa Record (để lọc)
  List<WeighingRecord> _allRecords = []; 
  
  // _filteredRecords: Danh sách HIỂN THỊ, chứa Record VÀ Summary
  List<dynamic> _filteredRecords = []; 
  List<dynamic> get filteredRecords => _filteredRecords;

  // --- State quản lý Filter ---
  String _selectedFilterType = 'Tên phôi keo';
  String get selectedFilterType => _selectedFilterType;
  DateTime? _selectedDate;
  DateTime? get selectedDate => _selectedDate;
  String _searchText = '';
  String get searchText => _searchText;

  HistoryController() {
    _loadData(); // Tải data gốc 1 lần
    searchController.addListener(() {
      if (_searchText != searchController.text) {
        _searchText = searchController.text;
        _runFilter(); // Chạy lọc và rebuild list
      }
    });
  }

  @override
  void dispose() {
    dateController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // --- 1. SỬA HÀM _loadData ---
  // Hàm này chỉ tải và parse vào _allRecords (List<WeighingRecord>)
  void _loadData() async {
    try {
      final url = Uri.parse('$_apiBaseUrl/api/history');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      List<WeighingRecord> tempRecords = [];

      if (response.statusCode == 200) {
        final List<dynamic> groupedData = json.decode(response.body);

        for (var group in groupedData) {
          final List<dynamic> recordsJson = group['records'];
          
          for (var jsonItem in recordsJson) {
            tempRecords.add(WeighingRecord(
              maCode: jsonItem['maCode'] as String,
              ovNO: jsonItem['ovNO'] as String,
              package: jsonItem['package'] ?? 0,
              mUserID: jsonItem['mUserID'].toString(),
              qtys: (jsonItem['qtys'] as num? ?? 0.0).toDouble(),
              mixTime: DateTime.parse(jsonItem['mixTime']),
              realQty: (jsonItem['realQty'] as num? ?? 0.0).toDouble(),
              isSuccess: true,
              loai: jsonItem['loai'],
              soLo: jsonItem['soLo'] ?? 0,
              tenPhoiKeo: jsonItem['tenPhoiKeo'],
              soMay: jsonItem['soMay'].toString(),
              nguoiThaoTac: jsonItem['nguoiThaoTac'],
              
              // (Chúng ta sẽ gán thông tin summary khi chạy _runFilter)
            ));
          }
        }
        
        _allRecords = tempRecords; // Gán vào danh sách GỐC
        _allRecords.sort((a, b) => b.mixTime!.compareTo(a.mixTime!)); // Sắp xếp list gốc
        
      } else {
        if (kDebugMode) {
          print('Lỗi tải lịch sử: ${response.statusCode}');
        }
        _allRecords = [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi mạng khi tải lịch sử: $e');
      }
      _allRecords = [];
    }
    
    // Sau khi tải xong, chạy filter (và tạo nhóm) lần đầu
    _runFilter(); 
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // --- HÀM _runFilter ---
  // Hàm này sẽ LỌC từ _allRecords, sau đó NHÓM và tạo ra _filteredRecords
  void _runFilter() {
    
    // Bắt đầu bằng danh sách gốc (chỉ WeighingRecord)
    List<WeighingRecord> filteredRecords = _allRecords; 

    // Lọc theo Ngày
    if (_selectedDate != null) {
      filteredRecords = filteredRecords
          .where((record) => _isSameDay(record.mixTime, _selectedDate))
          .toList();
    }

    // Lọc theo Từ khóa
    if (_searchText.isNotEmpty) {
      String query = _searchText.toLowerCase();
      filteredRecords = filteredRecords.where((record) {
        if (_selectedFilterType == 'Tên phôi keo') {
          return record.tenPhoiKeo?.toLowerCase().contains(query) ?? false;
        } else if (_selectedFilterType == 'Mã code') {
          return record.maCode.toLowerCase().contains(query);
        } else if (_selectedFilterType == 'OVNO') {
          return record.ovNO.toLowerCase().contains(query);
        }
        return false;
      }).toList();
    }

    // 3. NHÓM (Tương tự logic trong HistoryTable cũ)
    Map<String, List<WeighingRecord>> groupedData = {};
    for (var record in filteredRecords) {
      (groupedData[record.ovNO] ??= []).add(record);
    }

    // 4. TẠO LIST HIỂN THỊ (List<dynamic>)
    List<dynamic> newDisplayList = [];
    groupedData.forEach((ovNO, recordList) {
      
      // Thêm các record của nhóm
      newDisplayList.addAll(recordList);

      // --- TÍNH TOÁN TÓM TẮT ---
      // (Phần này bị thiếu ở API, chúng ta phải tra cứu MOCK)
      double totalNhap = 0.0;
      double totalXuat = 0.0;

      for (var record in recordList) { // Chỉ tính tổng các record đã lọc
        if (record.loai == 'nhap') {
          totalNhap += record.realQty ?? 0.0;
        } else if (record.loai == 'xuat') {
          totalXuat += record.realQty ?? 0.0;
        }
      }
      
      final workItem = mockWorkData[ovNO]; // Tạm thời tra cứu mock
      final memo = workItem?['Memo'] as String?;
      final totalTargetQty = (workItem?['Qty'] as num? ?? 0.0).toDouble();
      // --- KẾT THÚC TÍNH TOÁN ---

      // Thêm hàng tóm tắt
      newDisplayList.add(SummaryData(
        ovNO: ovNO,
        memo: memo,
        totalTargetQty: totalTargetQty,
        totalNhap: totalNhap,
        totalXuat: totalXuat,
      ));
    });

    _filteredRecords = newDisplayList; // Gán List<dynamic>
    notifyListeners(); // Thông báo cho UI cập nhật
  }

  // --- (Các hàm updateFilterType, updateSelectedDate, clearSelectedDate giữ nguyên) ---
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