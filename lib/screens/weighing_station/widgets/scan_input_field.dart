import 'package:flutter/material.dart';

class ScanInputField extends StatefulWidget {
  // Thêm một hàm callback. Widget này sẽ gọi nó khi người dùng nhấn Scan.
  final Function(String code) onScan;

  const ScanInputField({super.key, required this.onScan});

  @override
  State<ScanInputField> createState() => _ScanInputFieldState();
}

class _ScanInputFieldState extends State<ScanInputField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleScan() {
    final code = _controller.text.trim();
    if (code.isNotEmpty) {
      widget.onScan(code); // Gọi callback để gửi code lên cho màn hình cha
      _controller.clear(); // Xóa text sau khi scan
      FocusScope.of(context).unfocus(); // Ẩn bàn phím
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (phần màu sắc giữ nguyên)
    const Color fillColor = Color(0xFFE8F5E9);
    const Color borderColor = Color(0xFFB9E5BC);
    const Color buttonColor = Color(0xFF4CAF50);

    return TextField(
      controller: _controller,
      onSubmitted: (_) => _handleScan(), // Cho phép nhấn Enter để scan
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
            onPressed: _handleScan, // Gọi hàm xử lý scan
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