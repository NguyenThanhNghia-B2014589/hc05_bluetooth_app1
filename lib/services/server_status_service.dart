import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ServerStatusService extends ChangeNotifier {
  static final ServerStatusService _instance = ServerStatusService._internal();
  factory ServerStatusService() => _instance;
  ServerStatusService._internal();

  bool _isServerConnected = false;
  bool get isServerConnected => _isServerConnected;

  Timer? _timer;

  Future<void> startMonitoring() async {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => checkServer());
    await checkServer(); // Kiểm tra ngay lúc khởi tạo
  }

  Future<void> checkServer() async {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3636';
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/ping'))
          .timeout(const Duration(seconds: 3));
      final ok = res.statusCode == 200;
      if (ok != _isServerConnected) {
        _isServerConnected = ok;
        notifyListeners();
      }
    } catch (_) {
      if (_isServerConnected) {
        _isServerConnected = false;
        notifyListeners();
      }
    }
  }

  void disposeMonitoring() {
    _timer?.cancel();
  }
}
