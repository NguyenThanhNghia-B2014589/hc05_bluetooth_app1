import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Cần để format ngày
import '../../data/weighing_data.dart';
import '../../services/bluetooth_service.dart';
import '../../widgets/main_app_bar.dart';
import 'widgets/history_table.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  late List<WeighingRecord> _allRecords; // Danh sách đầy đủ
  List<WeighingRecord> _filteredRecords = []; // Danh sách đã lọc

  String _selectedFilterType = 'Tên phôi keo'; // Giữ state cho Dropdown
  DateTime? _selectedDate; // Giữ state cho Date Picker
  String _searchText = ''; // Giữ state cho Search Text

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
      _runFilter();
    });
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _runFilter() {
    List<WeighingRecord> results = _allRecords;

    // 1. Lọc theo Ngày (nếu có)
    if (_selectedDate != null) {
      results = results
          .where((record) => _isSameDay(record.thoiGianCan, _selectedDate))
          .toList();
    }

    // 2. Lọc theo Từ khóa tìm kiếm (nếu có)
    if (_searchText.isNotEmpty) {
      String query = _searchText.toLowerCase();
      
      results = results.where((record) {
        if (_selectedFilterType == 'Tên phôi keo') {
          return record.tenPhoiKeo.toLowerCase().contains(query);
        } else if (_selectedFilterType == 'Mã code') {
          return record.maCode.toLowerCase().contains(query);
        }
        // (Nếu bạn muốn tìm kiếm chung, bỏ if/else ở trên và dùng code này)
        // final tenPhoi = record.tenPhoiKeo.toLowerCase();
        // final maCode = record.maCode.toLowerCase();
        // final soLo = record.soLo.toLowerCase();
        // return tenPhoi.contains(query) || maCode.contains(query) || soLo.contains(query);
        
        return false;
      }).toList();
    }

    // Cập nhật UI
    setState(() {
      _filteredRecords = results;
    });
  }

  // Chuyển đổi mock map của bạn thành List<WeighingRecord>
  void _loadData() {
    // Tạm thời dùng hàm parse DateTime (bạn nên dùng thư viện intl cho chuẩn)
    DateTime parseMockDate(String dateStr) {
      // Format: '10:26 16/08/2025'
      try {
        final parts = dateStr.split(' '); // ['10:26', '16/08/2025']
        final timeParts = parts[0].split(':'); // ['10', '26']
        final dateParts = parts[1].split('/'); // ['16', '08', '2025']
        return DateTime(
          int.parse(dateParts[2]), // year
          int.parse(dateParts[1]), // month
          int.parse(dateParts[0]), // day
          int.parse(timeParts[0]), // hour
          int.parse(timeParts[1]), // minute
        );
      } catch (e) {
        return DateTime.now();
      }
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
  }
  
  @override
  void dispose() {
    _dateController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Tái sử dụng MainAppBar
      appBar: MainAppBar(
        title: 'LƯU TRÌNH CÂN CAO SU XƯỞNG ĐẾ',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Đẩy 2 item ra 2 bên
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Title
                const Text(
                  'Lịch sử cân',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                
                const SizedBox(width: 24), // Khoảng cách giữa Title và Filter
                
                // 2. Filter Bar (bọc trong Expanded)
                _buildFilterBar(),
              ],
            ),
            const SizedBox(height: 24),
            // 3. History Table
            Expanded(
              child: HistoryTable(records: _filteredRecords),
            ),
          ],
        ),
      ),
    );
  }

  // Widget xây dựng thanh Filter/Search
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Dropdown Loại Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
            decoration: BoxDecoration(
                color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilterType, // <-- Dùng state
                items: const [
                  DropdownMenuItem(
                      value: 'Tên phôi keo', child: Text('Tên phôi keo')),
                  DropdownMenuItem(
                      value: 'Mã code', child: Text('Mã code')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFilterType = value;
                    });
                    _runFilter(); // <-- Chạy lọc
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // 2. Date Picker
          SizedBox(
            width: 150,
            child: TextField(
              controller: _dateController,
              readOnly: true, // Không cho gõ
              decoration: InputDecoration(
                hintText: 'dd/mm/yyyy',
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.black, width: 1.0),
                ),
                
                // 3. Viền khi bấm vào (màu đen, dày hơn)
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.black, width: 2.0),
                ),

                // 4. Căn chỉnh lại padding bên trong ô
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                // Thêm icon Xóa và Lịch
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.calendar_today, size: 20),
                      onPressed: () async { // <-- Logic chọn ngày
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked; // <-- Lưu state
                            _dateController.text =
                                DateFormat('dd/MM/yyyy').format(picked);
                          });
                          _runFilter(); // <-- Chạy lọc
                        }
                      },
                    ),
                    // Chỉ hiện nút Xóa khi đã chọn ngày
                    if (_selectedDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () { // <-- Logic xóa ngày
                          setState(() {
                            _selectedDate = null; // <-- Xóa state
                            _dateController.clear();
                          });
                          _runFilter(); // <-- Chạy lọc
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          const VerticalDivider(),
          
          // 3. Search Field
          SizedBox(
            width: 250,
            child: TextField(
              controller: _searchController, // Listener đã được thêm trong initState
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                prefixIcon: Icon(Icons.search),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.black, width: 1.0),
                ),
                
                // 3. Viền khi bấm vào (màu đen, dày hơn)
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.black, width: 2.0),
                ),

                // 4. Căn chỉnh lại padding bên trong ô
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}