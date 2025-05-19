import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:minimal_chat_app/screens/post_detail_screen.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final postController = TextEditingController();
  Uint8List? selectedImageBytes;
  String? selectedImageName;

  // Đăng bài mới
  Future<void> createPost() async {
    if (postController.text.trim().isEmpty && selectedImageBytes == null) return;

    final postId = DateTime.now().millisecondsSinceEpoch.toString();
    String? imageUrl;

    try {
      // Upload ảnh lên Cloudinary nếu có ảnh được chọn
      if (selectedImageBytes != null && selectedImageName != null) {
        imageUrl = await uploadImageToCloudinary(selectedImageBytes!, selectedImageName!);
        if (imageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tải ảnh thất bại!')),
          );
          return;
        }
        print('Cloudinary imageUrl: $imageUrl'); // Gỡ lỗi
      }

      // Lấy username từ Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final username = userDoc.exists
          ? (userDoc.data() as Map<String, dynamic>)['username'] as String? ?? 'Không rõ'
          : 'Không rõ';

      // Chuẩn bị dữ liệu bài đăng
      final postData = {
        'postId': postId,
        'userId': currentUser.uid,
        'username': username,
        'content': postController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Chỉ thêm imageUrl nếu nó tồn tại
      if (imageUrl != null) {
        postData['imageUrl'] = imageUrl;
      }

      // Lưu bài đăng vào Firestore
      await FirebaseFirestore.instance.collection('posts').doc(postId).set(postData);

      postController.clear();
      setState(() {
        selectedImageBytes = null;
        selectedImageName = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng bài thành công!')),
      );
    } catch (e) {
      print('Lỗi tạo bài đăng: $e'); // Gỡ lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng bài thất bại: $e')),
      );
    }
  }

  // Xóa bài đăng
  Future<void> deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa bài thành công!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xóa bài thất bại: $e')),
      );
    }
  }

  // Chỉnh sửa bài đăng
  Future<void> editPost(String postId, String currentContent) async {
    final editController = TextEditingController(text: currentContent);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa bài đăng'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(hintText: 'Nhập nội dung mới'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, editController.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('posts').doc(postId).update({
          'content': result.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật bài thành công!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật bài thất bại: $e')),
        );
      }
    }
  }

  // Chọn và tải ảnh
  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes != null) {
      setState(() {
        selectedImageBytes = file.bytes;
        selectedImageName = file.name;
      });
    }
  }

  // Tải ảnh lên Cloudinary
  Future<String?> uploadImageToCloudinary(Uint8List fileBytes, String fileName) async {
    const cloudName = 'dxemb5w2b';
    const uploadPreset = 'post_upload'; // Có thể dùng 'post_upload' cho bài đăng

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));

    final response = await request.send();
    print('Trạng thái phản hồi Cloudinary: ${response.statusCode}'); // Gỡ lỗi

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      print('Dữ liệu phản hồi Cloudinary: $responseData'); // Gỡ lỗi
      final data = json.decode(responseData);
      return data['secure_url'];
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A40),
        title: const Text('Khám Phá', style: TextStyle(color: Colors.white)),
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Phần nhập bài đăng
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xFF2A2A40),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A3A55),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          controller: postController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Bạn đang nghĩ gì?',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                          maxLines: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: createPost,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.image, color: Colors.white70),
                      onPressed: pickImage,
                    ),
                    if (selectedImageBytes != null)
                      const Text(
                        'Đã chọn ảnh',
                        style: TextStyle(color: Colors.white70),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Danh sách bài đăng
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data!.docs;

                if (posts.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có bài đăng nào.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    // Gỡ lỗi: Kiểm tra dữ liệu tài liệu
                    print('Bài đăng ${post.id}: ${post.data()}');
                    final postId = post['postId'] as String;
                    final username = post['username'] as String? ?? 'Không rõ';
                    final content = post['content'] as String;
                    // Truy cập imageUrl an toàn
                    final imageUrl = (post.data() as Map<String, dynamic>?)?.containsKey('imageUrl') == true
                        ? post['imageUrl'] as String?
                        : null;
                    final isMe = post['userId'] == currentUser.uid;

                    return Card(
                      color: const Color(0xFF2A2A40),
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PostDetailScreen(
                                    postId: postId,
                                    userEmail: username, // Sử dụng username thay vì email
                                    content: content,
                                    imageUrl: imageUrl,
                                    isMe: isMe,
                                  ),
                                ),
                              );
                            },
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey,
                              child: Text(
                                username.isNotEmpty ? username[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              content.length > 50 ? '${content.substring(0, 47)}...' : content,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: isMe
                                ? PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                                    color: Colors.grey[900],
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        editPost(postId, content);
                                      } else if (value == 'delete') {
                                        deletePost(postId);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Chỉnh sửa', style: TextStyle(color: Colors.white)),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Xóa', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                          if (imageUrl != null && imageUrl.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Lỗi tải ảnh: $error'); // Gỡ lỗi
                                    return const Text(
                                      'Không thể tải ảnh',
                                      style: TextStyle(color: Colors.white70),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
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