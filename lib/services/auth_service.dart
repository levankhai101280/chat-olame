// Import thư viện Firebase Authentication
import 'package:firebase_auth/firebase_auth.dart';

// Định nghĩa lớp AuthService để xử lý các chức năng xác thực người dùng
class AuthService {
  // Khởi tạo một instance của FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Hàm đăng nhập với email và password
  Future<User?> signIn(String email, String password) async {
    // Sử dụng Firebase để đăng nhập với email và mật khẩu
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Trả về thông tin người dùng sau khi đăng nhập thành công
    return credential.user;
  }

  // Hàm đăng ký tài khoản mới với email và password
  Future<User?> register(String email, String password) async {
    // Sử dụng Firebase để tạo tài khoản mới
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Trả về thông tin người dùng sau khi tạo tài khoản thành công
    return credential.user;
  }

  // Hàm đăng xuất khỏi tài khoản hiện tại
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Thuộc tính để lấy người dùng hiện tại (nếu đã đăng nhập)
  User? get currentUser => _auth.currentUser;
}
