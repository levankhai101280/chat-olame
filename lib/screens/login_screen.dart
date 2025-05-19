// Import các gói cần thiết
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Dùng để xác thực người dùng
import 'package:minimal_chat_app/screens/AllScreen.dart';
import 'package:minimal_chat_app/screens/user_list_screen.dart'; // Màn hình chuyển đến sau khi đăng nhập thành công
import 'register_screen.dart'; // Màn hình chuyển đến nếu chưa có tài khoản

// Tạo widget có trạng thái (StatefulWidget) cho màn hình đăng nhập
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller để lấy giá trị email và password từ người dùng nhập
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Hàm xử lý đăng nhập
  void login() async {
    try {
      // Dùng Firebase để đăng nhập bằng email và mật khẩu
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Nếu thành công, chuyển đến màn hình danh sách người dùng
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AllScreen()),
      );
    } catch (e) {
      // Nếu lỗi, hiển thị thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C), // Màu nền tối hiện đại
      body: Center(
        child: SingleChildScrollView( // Giúp giao diện cuộn được khi bàn phím bật lên
          padding: const EdgeInsets.all(24), // Padding toàn màn hình
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon đại diện cho ứng dụng
              const Icon(Icons.chat_bubble_outline, size: 80, color: Colors.white),
              const SizedBox(height: 20),

              // Tiêu đề chào mừng
              const Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),

              // Ô nhập email
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email, color: Colors.white70),
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF2A2A40),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Ô nhập mật khẩu
              TextField(
                controller: passwordController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF2A2A40),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                obscureText: true, // Ẩn ký tự mật khẩu
              ),
              const SizedBox(height: 24),

              // Nút đăng nhập
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: login, // Gọi hàm login
                  icon: const Icon(Icons.login),
                  label: const Text('Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5), // Màu nút tím
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Chuyển sang màn hình đăng ký
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text(
                  'Don\'t have an account? Register here',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
