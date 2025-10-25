import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _soTheController = TextEditingController();
  final _matKhauController = TextEditingController();

  void _handleLogin() {
    // Tạm thời, chúng ta sẽ không kiểm tra logic vội
    // Cứ đăng nhập là sẽ chuyển trang
    
    // Sử dụng pushReplacementNamed để người dùng không thể "Back" về trang login
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _soTheController.dispose();
    _matKhauController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB0D9F3), // Màu nền xanh nhạt
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            // Đảm bảo nội dung luôn cao ít nhất bằng chiều cao màn hình
            minHeight: MediaQuery.of(context).size.height, 
          ),
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  // Giao diện cho màn hình RỘNG (như ảnh của bạn)
                  return _buildWideLayout();
                } else {
                  // Giao diện cho màn hình HẸP (cho điện thoại)
                  return _buildNarrowLayout();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  // Giao diện màn hình RỘNG (side-by-side)
  Widget _buildWideLayout() {
    return Row(
      children: [
        // Cột 1: Hình ảnh
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'lib/assets/images/weight_login.png', //ĐƯỜNG DẪN HÌNH ẢNH
                width: 400,
              ), 
            ],
          ),
        ),
        // Cột 2: Form đăng nhập
        Expanded(
          child: Center(
            child: _buildLoginForm(),
          ),
        ),
      ],
    );
  }

  // Giao diện màn hình HẸP (stacked)
  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/images/weight_login.png', //ĐƯỜNG DẪN HÌNH ẢNH
              width: 250,
            ),
            const SizedBox(height: 32),
            _buildLoginForm(),
          ],
        ),
      ),
    );
  }


  // Widget chứa Form đăng nhập (dùng chung cho cả 2 layout)
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
        mainAxisSize: MainAxisSize.min,
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
          // --- Số thẻ ---
          Text('Số thẻ', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          TextField(
            controller: _soTheController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const SizedBox(height: 16),
          // --- Mật khẩu ---
          Text('Mật khẩu', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          TextField(
            controller: _matKhauController,
            obscureText: true, // Ẩn mật khẩu
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const SizedBox(height: 32),
          // --- Nút Đăng nhập ---
          ElevatedButton(
            onPressed: _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1), // Màu tím
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('Đăng nhập', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}