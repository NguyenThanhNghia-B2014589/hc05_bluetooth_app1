import 'package:flutter/material.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // --- 1. TẠO MỘT MAP ĐỂ GIỮ CÁC LỰA CHỌN ---
  final Map<String, String> _historyRangeOptions = const {
    '30': '30 Ngày',
    '7': '7 Ngày',
    '15': '15 Ngày',
    '90': '90 Ngày',
    'all': 'Tất cả lịch sử',
  };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SettingsService(),
      builder: (context, child) {
        final settings = SettingsService();
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Cài đặt'),
          ),
          body: ListView( // Giữ ListView phòng khi bạn muốn thêm cài đặt khác
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Lấy lịch sử cân trong:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 8),
              //Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade400), // Thêm viền
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: settings.historyRange, // Lấy giá trị hiện tại
                    isExpanded: true,
                    icon: const Icon(Icons.calendar_today_outlined),
                    items: _historyRangeOptions.entries.map((entry) {
                      // entry.key = '7', entry.value = '7 Ngày'
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      // Cập nhật khi thay đổi
                      if (newValue != null) {
                        settings.updateHistoryRange(newValue);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}