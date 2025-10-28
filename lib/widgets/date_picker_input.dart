import 'package:flutter/material.dart';

class DatePickerInput extends StatelessWidget {
  final DateTime? selectedDate; // 1. Cho phép null
  final TextEditingController controller;
  final Function(DateTime) onDateSelected;
  final Function() onDateCleared; // 2. Thêm callback "Xóa"

  const DatePickerInput({
    super.key,
    required this.selectedDate,
    required this.controller,
    required this.onDateSelected,
    required this.onDateCleared, // 3. Thêm vào constructor
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220, // 4. Sửa width
      child: TextField(
        controller: controller,
        readOnly: true,
        style: const TextStyle(fontSize: 16), // Giữ cỡ chữ
        decoration: InputDecoration(
          hintText: 'dd/mm/yyyy',

          // 5. Thêm viền (giống code của bạn)
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Colors.black, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Colors.black, width: 2.0),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),

          // 6. Sửa logic SuffixIcon
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.calendar_today, size: 20),
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(), // Xử lý null
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null && picked != selectedDate) {
                    onDateSelected(picked);
                  }
                },
              ),
              
              // Chỉ hiện nút Xóa khi đã chọn ngày
              if (selectedDate != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    onDateCleared(); // Gọi callback "Xóa"
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}