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
        PopupMenuButton<String>(
          // Hàm xử lý khi chọn "Đăng xuất"
          onSelected: (value) {
            if (value == 'logout') {
              // 1. Ngắt kết nối Bluetooth (nếu đang kết nối)
              bluetoothService.disconnect();
              
              // 2. Quay về trang login và xóa tất cả các màn hình cũ
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login', 
                (Route<dynamic> route) => false // Xóa hết stack
              );
            }
          },
          // Icon hiển thị trên AppBar
          icon: const Icon(Icons.person, color: Colors.black54), 
          tooltip: 'Tuy chọn',
          // Hàm này xây dựng các mục trong menu
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            
            // Mục "Đăng xuất"
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red.shade700), // Icon đăng xuất
                  const SizedBox(width: 12),
                  const Text('Đăng xuất'),
                ],
              ),
            ),

            // Bạn có thể thêm các mục khác ở đây nếu muốn
            // PopupMenuItem<String>(
            //   value: 'settings',
            //   child: Row(children: [Icon(Icons.settings), Text('Cài đặt')]),
            // ),
          ],
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