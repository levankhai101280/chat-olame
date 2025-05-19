import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

import '../widgets/message_bubble.dart';
import 'login_screen.dart';
import 'dart:typed_data';


class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserEmail;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserEmail,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser!;
  final scrollController = ScrollController();

  // Tạo ID cho cuộc trò chuyện
  String get chatId {
    final ids = [currentUser.uid, widget.otherUserId]..sort();
    return ids.join('_');
  }

  // Gửi tin nhắn văn bản hoặc ảnh
  void sendMessage({String? text, String? fileUrl, String? fileType}) async {
    if ((text == null || text.trim().isEmpty) && fileUrl == null) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': text?.trim(),
      'fileUrl': fileUrl,
      'fileType': fileType,
      'senderId': currentUser.uid,
      'senderEmail': currentUser.email,
      'timestamp': FieldValue.serverTimestamp(),
    });

    messageController.clear();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Upload ảnh lên Cloudinary
  Future<String?> uploadImageToCloudinary({
  required Uint8List fileBytes,
  required String fileName,
}) async {
  const cloudName = 'dxemb5w2b';
  const uploadPreset = 'chat_upload_preset';

  final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  final request = http.MultipartRequest('POST', url)
    ..fields['upload_preset'] = uploadPreset
    ..files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
    ));

  final response = await request.send();

  if (response.statusCode == 200) {
    final responseData = await response.stream.bytesToString();
    final data = json.decode(responseData);
    return data['secure_url'];
  } else {
    print('Upload thất bại: ${response.statusCode}');
    return null;
  }
}

  // Chọn ảnh và gửi
  Future<void> pickAndSendImage() async {
  final result = await FilePicker.platform.pickFiles(type: FileType.image);
  if (result == null || result.files.isEmpty) return;

  final file = result.files.first;
  if (file.bytes == null) return;

  final imageUrl = await uploadImageToCloudinary(
    fileBytes: file.bytes!,
    fileName: file.name,
  );

  if (imageUrl != null) {
    final fileType = file.extension ?? 'image';
    sendMessage(fileUrl: imageUrl, fileType: fileType);
  }
}


  Stream<QuerySnapshot> getChatStream() {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A40),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(widget.otherUserEmail, style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getChatStream(),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  controller: scrollController,
                  itemCount: messages.length,
                  itemBuilder: (ctx, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == currentUser.uid;

                    return MessageBubble(
                      message: msg['text'],
                      sender: '',
                      isMe: isMe,
                      fileUrl: msg['fileUrl'],
                      fileType: msg['fileType'],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A40),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, -2)),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.white70),
                  onPressed: pickAndSendImage,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A55),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn...',
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
                    onPressed: () => sendMessage(text: messageController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
