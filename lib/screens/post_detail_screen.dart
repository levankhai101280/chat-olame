import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String userEmail;
  final String content;
  final String? imageUrl;
  final bool isMe;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.userEmail,
    required this.content,
    this.imageUrl,
    required this.isMe,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final commentController = TextEditingController();

  // Gửi bình luận
  Future<void> addComment() async {
    if (commentController.text.trim().isEmpty) return;

    final commentId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .set({
        'commentId': commentId,
        'userId': currentUser.uid,
        'userEmail': currentUser.email,
        'content': commentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thêm bình luận thất bại: $e')),
      );
    }
  }

  // Xóa bình luận
  Future<void> deleteComment(String commentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa bình luận thành công!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xóa bình luận thất bại: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A40),
        title: Text(widget.userEmail, style: const TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Hiển thị bài đăng
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: const Color(0xFF2A2A40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Text(
                            widget.userEmail.isNotEmpty
                                ? widget.userEmail[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.userEmail,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.content,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.imageUrl!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Lỗi tải ảnh: $error');
                            return const Text(
                              'Không thể tải ảnh',
                              style: TextStyle(color: Colors.white70),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Phần nhập bình luận
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xFF2A2A40),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A55),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Viết bình luận...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: addComment,
                  ),
                ),
              ],
            ),
          ),
          // Danh sách bình luận
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!.docs;

                if (comments.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có bình luận nào.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final userEmail = comment['userEmail'] as String;
                    final content = comment['content'] as String;
                    final commentId = comment['commentId'] as String;
                    final isMe = comment['userId'] == currentUser.uid;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Text(
                          userEmail.isNotEmpty ? userEmail[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        userEmail,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        content,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: isMe
                          ? IconButton(
                              icon: const Icon(Icons.delete, color: Colors.white70),
                              onPressed: () => deleteComment(commentId),
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}