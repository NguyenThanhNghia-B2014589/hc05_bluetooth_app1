import 'package:flutter/material.dart';
import 'screens/scan_screen.dart';
import 'screens/weighing_station_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lưu trình Cân',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8), // Màu nền giống trong hình
      ),
      // Khai báo các màn hình (route)
      initialRoute: '/scan', // Bắt đầu ở màn hình quét
      routes: {
        '/scan': (context) => const ScanScreen(),
        '/weighing_station': (context) => const WeighingStationScreen(),
      },
    );
  }
}