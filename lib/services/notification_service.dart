import 'package:flutter/material.dart';
import '../widgets/toast_widget.dart';

// Enum để định nghĩa các loại thông báo
enum ToastType { success, error, info }

class NotificationService {
  // Singleton pattern để dễ dàng truy cập từ mọi nơi
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Hàm chính để hiển thị thông báo
  void showToast({
    required BuildContext context,
    required String message,
    ToastType type = ToastType.info,
  }) {
    // Lấy OverlayState để có thể chèn widget lên trên
    final overlay = Overlay.of(context);
    OverlayEntry? overlayEntry;

    // Lấy thông tin style dựa trên loại thông báo
    final icon = _getIconForType(type);
    final color = _getColorForType(type);

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 20.0, // Khoảng cách từ đỉnh màn hình
        left: 0,
        right: 0,
        child: ToastWidget(
          message: message,
          icon: icon,
          backgroundColor: color,
          onDismissed: () {
            // Khi animation kết thúc, remove widget khỏi cây
            overlayEntry?.remove();
          },
        ),
      ),
    );

    // Chèn widget vào cây Overlay
    overlay.insert(overlayEntry);
  }

  // Hàm helper để lấy màu sắc
  Color _getColorForType(ToastType type) {
  switch (type) {
    case ToastType.success:
      return Colors.green.shade600;
    case ToastType.error:
      return Colors.red.shade600;
    default:
      return Colors.blue.shade600;
  }
}

  // Hàm helper để lấy icon
  IconData _getIconForType(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle_outline;
      case ToastType.error:
        return Icons.highlight_off;
      default:
        return Icons.info_outline;
    }
  }
}