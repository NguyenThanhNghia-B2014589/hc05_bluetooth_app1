import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';
import 'bluetooth_status_action.dart';
import '../services/auth_service.dart';

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
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'logout') {
              bluetoothService.disconnect();
              AuthService().logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login', 
                (Route<dynamic> route) => false
              );
            }
          },
          icon: const Icon(Icons.person, color: Colors.black, size: 30.0,), // Icon Người
          tooltip: 'Tùy chọn',
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  const Text('Đăng xuất'),
                ],
              ),
            ),
          ],
        ),

        // --- 2. Tên (AnimatedBuilder) ---
        AnimatedBuilder(
          animation: AuthService(), 
          builder: (context, child) {
            final auth = AuthService();
            if (!auth.isLoggedIn) {
              return const SizedBox.shrink(); // Ẩn nếu chưa đăng nhập
            }
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Text(
                  '${auth.userName} (${auth.mUserID})',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                  ),
                ),
              ),
            );
          },
        ),
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