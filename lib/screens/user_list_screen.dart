import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class UserListScreen extends StatelessWidget {
  final currentUser = FirebaseAuth.instance.currentUser;

  UserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A40),
        elevation: 0.5,
        foregroundColor: Colors.white,
        title: const Text(
          "Tin nhắn",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            color: Colors.grey[900],
            onSelected: (value) async {
              if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Đăng xuất'),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Lỗi tải danh sách người dùng',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null || !data.containsKey('uid') || !data.containsKey('username')) {
              return false;
            }
            final uid = data['uid'] as String?;
            return uid != currentUser?.uid;
          }).toList();

          if (users.isEmpty) {
            return const Center(
              child: Text(
                'Không có người dùng nào để nhắn tin.',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (ctx, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;
              final username = data['username'] as String? ?? 'Không rõ';
              final avatarUrl = data['avatarUrl'] as String?;
              final initials = username.isNotEmpty ? username[0].toUpperCase() : '?';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Material(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF2A2A40),
                  elevation: 1,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            otherUserId: data['uid'] as String,
                            otherUserEmail: username, // Sử dụng username thay vì email
                          ),
                        ),
                      );
                    },
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      leading: CircleAvatar(
                        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                            ? NetworkImage(avatarUrl)
                            : const AssetImage('assets/images/avatar.jpg') as ImageProvider,
                        backgroundColor: Colors.grey,
                        child: (avatarUrl == null || avatarUrl.isEmpty)
                            ? Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: const Text(
                        'Nhấn để bắt đầu trò chuyện',
                        style: TextStyle(color: Colors.white60),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white38),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}