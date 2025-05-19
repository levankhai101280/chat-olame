import 'package:flutter/material.dart';
import 'package:minimal_chat_app/screens/ProfileScreen.dart';
import 'package:minimal_chat_app/screens/explore_screen.dart';
import 'package:minimal_chat_app/screens/post_screen.dart';
import 'user_list_screen.dart'; // Màn hình danh sách người dùng

class AllScreen extends StatefulWidget {
  const AllScreen({super.key});

  @override
  State<AllScreen> createState() => _AllScreenState();
}

class _AllScreenState extends State<AllScreen> {
  int _selectedIndex = 0;

  // Danh sách các màn hình tương ứng với các tab bottom navigation
  final List<Widget> _pages = [
    UserListScreen(), // Tab Tin Nhắn
    PostScreen(), // Tab Khám Phá 
    ExploreScreen(),  // Tab Đi Dạo
    Center(child: Text('Audio - Chưa có nội dung')),      // Tab Audio
    ProfileScreen(),    // Tab Hồ Sơ
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Hiển thị màn hình tương ứng tab
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF4F46E5), // màu tím như nút login
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Tin Nhắn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Khám Phá',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: 'Đi Dạo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic),
            label: 'Audio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Hồ Sơ',
          ),
        ],
      ),
    );
  }
}
