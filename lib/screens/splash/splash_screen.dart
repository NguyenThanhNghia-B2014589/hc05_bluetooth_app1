import 'dart:io'; // Để kiểm tra nền tảng (Platform)
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Chạy kiểm tra quyền ngay khi màn hình được tạo
    _checkPermissionsAndNavigate();
  }

  Future<void> _checkPermissionsAndNavigate() async {
    // 1. Chỉ kiểm tra quyền nếu là Android
    if (Platform.isAndroid) {
      // Lấy thông tin phiên bản Android
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      // Danh sách quyền cần xin
      List<Permission> permissionsToRequest = [];

      if (sdkInt >= 31) {
        // Android 12 (API 31) trở lên
        permissionsToRequest.addAll([
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ]);
      } else {
        // Android 11 (API 30) trở xuống
        // Cần quyền Vị trí để quét Bluetooth
        permissionsToRequest.add(Permission.location);
      }

      // 2. Yêu cầu các quyền
      if (permissionsToRequest.isNotEmpty) {
        await permissionsToRequest.request();
      }
    }

    // 3. ✅ CHECK MOUNTED sau async operation
    if (!mounted) return;

    // 4. Chuyển sang trang Login
    // (Chúng ta thêm 1 chút delay để người dùng kịp thấy Splash)
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 5. ✅ CHECK MOUNTED lần nữa sau delay
    if (!mounted) return;
    
    // 6. ✅ Dùng Navigator với context an toàn
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    // Bạn có thể đặt logo ở đây
    return const Scaffold(
      backgroundColor: Color(0xFFB0D9F3), // Giống màu nền Login
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Đang kiểm tra quyền...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}