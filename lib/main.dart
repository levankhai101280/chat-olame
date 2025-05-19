import 'package:flutter/material.dart';                     //  Thư viện giao diện chính của Flutter
import 'package:firebase_core/firebase_core.dart';          //  Khởi tạo Firebase
import 'screens/login_screen.dart';                         //  Màn hình đăng nhập
import 'screens/chat_screen.dart';                          //  Màn hình chat (đã import nhưng không dùng ở đây)
import 'firebase_options.dart';                             //  Tùy chọn Firebase, tạo từ lệnh `flutterfire configure`

void main() async {
  WidgetsFlutterBinding.ensureInitialized();                //  Đảm bảo Flutter binding đã sẵn sàng trước khi chạy async
  await Firebase.initializeApp(                             //  Khởi tạo Firebase trước khi app chạy
    options: DefaultFirebaseOptions.currentPlatform,        //  Dùng cấu hình tương ứng với nền tảng đang chạy (iOS, Android, Web)
  );
  runApp(const ChatApp());                                  //  Khởi chạy ứng dụng
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',                                    //  Tiêu đề app
      themeMode: ThemeMode.dark,                            //  Sử dụng theme tối
      darkTheme: ThemeData.dark().copyWith(                 //  Tuỳ chỉnh giao diện tối
        scaffoldBackgroundColor: const Color(0xFF1E1E2C),   //  Màu nền chính
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4F46E5),                       //  Màu chính (nút gửi, appbar...)
          secondary: Colors.tealAccent,                     //  Màu phụ (nút tải tệp, điểm nhấn...)
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white70),     //  Màu chữ trong TextField
        ),
      ),
      debugShowCheckedModeBanner: false,                    //  Tắt banner DEBUG ở góc trên phải
      home: const LoginScreen(),                            //  Màn hình khởi đầu là Login
    );
  }
}
