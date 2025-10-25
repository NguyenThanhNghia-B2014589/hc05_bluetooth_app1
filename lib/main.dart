import 'package:flutter/material.dart';
import 'screens/connect_blu/connect_blu_screen.dart';
import 'screens/weighing_station/weighing_station_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/history/history_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weighing Station App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color.fromARGB(255, 173, 207, 241), // Màu nền
      ),
      // Khai báo các màn hình (route)
      initialRoute: '/login', // Bắt đầu ở màn hình login
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/scan': (context) => const ScanScreen(),
        '/weighing_station': (context) => const WeighingStationScreen(),
        '/history': (context) => const HistoryScreen(),
      },
    );
  }
}