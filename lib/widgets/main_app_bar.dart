import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';
import 'bluetooth_status_action.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading; // Cho phép tùy chỉnh nút leading (như nút Back)
  final BluetoothService bluetoothService;

  const MainAppBar({
    super.key,
    required this.title,
    required this.bluetoothService,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // Các thuộc tính style chung
      elevation: 0,
      backgroundColor: Colors.white, // Bạn có thể đặt màu nền chung ở đây
      foregroundColor: Colors.black87,   // Màu chung cho icon và text

      // Title và Leading tùy biến
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: leading,

      // Actions cố định cho layout này
      actions: [
        const Icon(Icons.person, color: Colors.black54),
        const SizedBox(width: 8),
        BluetoothStatusAction(bluetoothService: bluetoothService),
        const SizedBox(width: 8),
      ],
    );
  }

  // Bắt buộc phải có khi implements PreferredSizeWidget
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}