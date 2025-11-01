import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _soTheController = TextEditingController();
  String _selectedFactory = 'LHG';
  bool _isLoading = false;
  final String _apiBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3636';

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
      final url = Uri.parse('$_apiBaseUrl/api/auth/login');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'mUserID': soThe}),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // ✅ Lưu thông tin đăng nhập
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('soThe', soThe);
        await prefs.setString('factory', _selectedFactory);

        NotificationService().showToast(
          context: context,
          message: data['message'] ?? 'Đăng nhập thành công!',
          type: ToastType.success,
        );

        // Đợi nhẹ cho toast hiện xong
        await Future.delayed(const Duration(seconds: 4));
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        NotificationService().showToast(
          context: context,
          message: data['message'] ?? 'Số thẻ không tồn tại.',
          type: ToastType.error,
        );
      }
    } catch (_) {
      if (!mounted) return;
      NotificationService().showToast(
        context: context,
        message: 'Lỗi kết nối: Không thể kết nối tới server.',
        type: ToastType.error,
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _soTheController.dispose();
    super.dispose();
  }

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
          Text('Đăng nhập',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          const SizedBox(height: 32),
          Text('Số thẻ',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
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
              value: _selectedFactory,
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
