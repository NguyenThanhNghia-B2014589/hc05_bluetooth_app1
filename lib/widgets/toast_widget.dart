import 'dart:async';
import 'package:flutter/material.dart';

// Widget này quản lý animation và giao diện của chính nó
class ToastWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onDismissed; // Callback để báo cho service biết khi nào cần remove

  const ToastWidget({
    super.key,
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.onDismissed,
  });

  @override
  State<ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -2.0), // Bắt đầu từ phía trên màn hình
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Bắt đầu animation đi vào
    _controller.forward();

    // Tự động ẩn đi sau 3 giây
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismissed();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SlideTransition(
        position: _offsetAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Material(
            elevation: 10.0,
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: Colors.white, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Ví dụ thông báo thành công
// NotificationService().showToast(
// context: context,
// message: 'Đã hoàn tất thao tác cân!',
// type: ToastType.success,
// );

// Ví dụ thông báo lỗi
// NotificationService().showToast(
//   context: context,
//   message: 'Không thể kết nối với máy chủ.',
//   type: ToastType.error,
// );

// Ví dụ thông báo thông tin
// NotificationService().showToast(
//   context: context,
//   message: 'Vui lòng kiểm tra lại số liệu.',
//   type: ToastType.info,
// );