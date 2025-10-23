import 'package:flutter/material.dart';

// 1. Chuyển thành StatelessWidget
class ScanInputField extends StatelessWidget {
  
  // 2. Nhận controller và hàm onScan từ bên ngoài
  final TextEditingController controller;
  final Function(String code) onScan;

  const ScanInputField({
    super.key,
    required this.controller,
    required this.onScan,
  });

  // 3. Hàm xử lý _handleScan (giờ là hàm private của StatelessWidget)
  void _handleScan(BuildContext context) {
    final code = controller.text.trim();
    if (code.isNotEmpty) {
      onScan(code); // Chỉ gọi callback, KHÔNG clear()
      FocusScope.of(context).unfocus(); // Ẩn bàn phím
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color fillColor = Color(0xFFE8F5E9);
    const Color borderColor = Color(0xFFB9E5BC);
    const Color buttonColor = Color(0xFF4CAF50);

    return TextField(
      controller: controller, // 4. Dùng controller được truyền vào
      onSubmitted: (_) => _handleScan(context), // 5. Gọi hàm _handleScan
      decoration: InputDecoration(
        hintText: 'Scan hoặc Nhập mã tại đây...',
        hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: borderColor, width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: buttonColor, width: 2.0),
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(5.0),
          child: ElevatedButton.icon(
            onPressed: () => _handleScan(context), // 6. Gọi hàm _handleScan
            icon: const Icon(Icons.qr_code_scanner, size: 20),
            label: const Text('Scan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              minimumSize: const Size(80, 36),
            ),
          ),
        ),
      ),
    );
  }
}