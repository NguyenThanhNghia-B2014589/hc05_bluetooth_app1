import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_helper.dart';
import '../../services/sync_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _soTheController = TextEditingController();
  String _selectedFactory = 'LHG';
  bool _isLoading = false;

  // Địa chỉ server nội bộ
  final String _apiBaseUrl =
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3636';

  @override
  void dispose() {
    _soTheController.dispose();
    super.dispose();
  }

  // ===== HÀM ĐĂNG NHẬP =====
  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    final soThe = _soTheController.text.trim();
    if (soThe.isEmpty) {
      NotificationService().showToast(
        context: context,
        message: 'Vui lòng nhập số thẻ.',
        type: ToastType.info,
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      // BƯỚC 1: KIỂM TRA DATABASE CỤC BỘ
      final db = await DatabaseHelper().database;
      final List<Map<String, dynamic>> localUser = await db.query(
        'VmlPersion',
        columns: ['nguoiThaoTac'],
        where: 'mUserID = ?',
        whereArgs: [soThe],
      );

      if (localUser.isEmpty) {
        throw Exception(
            'Số thẻ không tồn tại.\nVui lòng kết nối mạng và thử lại (để đồng bộ).');
      }

      // BƯỚC 2: ĐĂNG NHẬP THÀNH CÔNG (OFFLINE)
      final userName = localUser.first['nguoiThaoTac'] as String;

      // Lưu vào AuthService (cho AppBar)
      AuthService().login(soThe, userName);

      // Lưu vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('soThe', soThe);
      await prefs.setString('factory', _selectedFactory);
      if (!mounted) return;
      NotificationService().showToast(
        context: context,
        message: 'Đăng nhập thành công! Xin chào $userName 👋',
        type: ToastType.success,
      );

      // BƯỚC 3: KIỂM TRA MẠNG VÀ SERVER BACKEND (LAN)
      if (!mounted) return;

      final connectivityResults = await Connectivity().checkConnectivity();
      final hasNetwork = connectivityResults.isNotEmpty &&
          !connectivityResults.contains(ConnectivityResult.none);

      if (hasNetwork) {
        // Kiểm tra server LAN có phản hồi không
        final serverOk = await _canReachLocalServer('$_apiBaseUrl/api/ping');
        if (serverOk) {
          if (kDebugMode) print('✅ Kết nối server nội bộ OK. Bắt đầu đồng bộ...');
          // Chạy đồng bộ ngầm
          SyncService().syncAllData().catchError((e) {
            if (kDebugMode) print('Lỗi đồng bộ ngầm: $e');
          });
        } else {
          if (kDebugMode) print('⚠️ Có mạng nhưng không kết nối được server backend.');
        }
      } else {
        if (kDebugMode) print('⚠️ Không có kết nối mạng.');
      }

      // BƯỚC 4: CHUYỂN TRANG
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return;
      _soTheController.clear();
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (!mounted) return;
      NotificationService().showToast(
        context: context,
        message: e.toString().replaceFirst("Exception: ", ""),
        type: ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===== HÀM KIỂM TRA SERVER LAN =====
  Future<bool> _canReachLocalServer(String serverUrl) async {
    try {
      final response = await http
          .get(Uri.parse(serverUrl))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ===== GIAO DIỆN =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB0D9F3),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) =>
                  constraints.maxWidth > 800 ? _buildWideLayout() : _buildNarrowLayout(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: Image.asset('lib/assets/images/weight_login.png', width: 400),
          ),
        ),
        Expanded(child: Center(child: _buildLoginForm())),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('lib/assets/images/weight_login.png', width: 250),
          const SizedBox(height: 32),
          _buildLoginForm(),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Đăng nhập',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Số thẻ',
            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _soTheController,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const SizedBox(height: 32),
          DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedFactory,
              icon: const Icon(Icons.factory_outlined),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              items: ['LHG', 'LYV', 'LVL', 'LAZ', 'LZS', 'LYM']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedFactory = v ?? 'LHG'),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Đăng nhập', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
