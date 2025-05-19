import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:minimal_chat_app/screens/chat_screen.dart';

class UserDetailScreen extends StatelessWidget {
  final String userId;
  final String email;

  const UserDetailScreen({
    super.key,
    required this.userId,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A40),
        title: Text(email, style: const TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          // Handle missing fields
          final gender = userData.containsKey('gender') ? userData['gender'] as String? ?? 'Chưa cập nhật' : 'Chưa cập nhật';
          final location = userData.containsKey('location') ? userData['location'] as String? ?? 'Chưa cập nhật' : 'Chưa cập nhật';
          final maritalStatus = userData.containsKey('maritalStatus') ? userData['maritalStatus'] as String? ?? 'Chưa cập nhật' : 'Chưa cập nhật';
          final bio = userData.containsKey('bio') ? userData['bio'] as String? ?? 'Chưa có giới thiệu' : 'Chưa có giới thiệu';
          final hobbies = userData.containsKey('hobbies') ? (userData['hobbies'] as List<dynamic>?)?.cast<String>() ?? [] : [];
          final birthDate = userData.containsKey('birthDate') ? userData['birthDate'] as String? ?? 'Chưa cập nhật' : 'Chưa cập nhật';
          final avatarUrl = userData['avatarUrl'] as String?;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar và email
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? NetworkImage(avatarUrl)
                          : const AssetImage('assets/images/avatar.jpg') as ImageProvider,
                      backgroundColor: Colors.grey,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? Text(
                              email.isNotEmpty ? email[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontSize: 32),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        email,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Thông tin chi tiết
                _buildInfoRow('Giới tính', gender),
                _buildInfoRow('Nơi ở', location),
                _buildInfoRow('Tình trạng', maritalStatus),
                _buildInfoRow('Ngày sinh', birthDate),
                const SizedBox(height: 16),
                const Text(
                  'Giới thiệu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  bio,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sở thích',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: hobbies.isNotEmpty
                      ? hobbies
                          .map((hobby) => Chip(
                                label: Text(hobby),
                                backgroundColor: const Color(0xFF3A3A55),
                                labelStyle: const TextStyle(color: Colors.white70),
                              ))
                          .toList()
                      : [const Text('Chưa có sở thích', style: TextStyle(color: Colors.white70))],
                ),
                const Spacer(),
                // Nút nhắn tin
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            otherUserId: userId,
                            otherUserEmail: email,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('Nhắn tin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}