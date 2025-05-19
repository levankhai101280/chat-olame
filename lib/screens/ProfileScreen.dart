import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  String? avatarUrl;
  String? username;

  @override
  void initState() {
    super.initState();
    print('Current user: ${user?.uid}, email: ${user?.email}');
    loadUserDataFromFirestore();
  }

  Future<void> loadUserDataFromFirestore() async {
    final uid = user?.uid;
    if (uid == null) {
      print('Người dùng chưa đăng nhập');
      if (mounted) {
        setState(() {
          avatarUrl = null;
          username = null;
        });
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          final url = data['avatarUrl'] as String?;
          final userName = data['username'] as String? ?? 'Không có username';
          setState(() {
            avatarUrl = url?.isNotEmpty == true ? url : null;
            username = userName;
          });
        }
      }
    } catch (e) {
      print('Lỗi tải dữ liệu người dùng: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tải dữ liệu người dùng thất bại: $e')),
        );
      }
    }
  }

  Future<void> saveAvatarUrlToFirestore(String url) async {
    final uid = user?.uid;
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để lưu avatar!')),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'avatarUrl': url,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Lỗi lưu avatar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lưu avatar thất bại: $e')),
        );
      }
    }
  }

  Future<String?> uploadImageToCloudinary(Uint8List fileBytes, String fileName) async {
    const cloudName = 'dxemb5w2b';
    const uploadPreset = 'avatar_upload';

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));

    try {
      final response = await request.send();
      print('Trạng thái phản hồi Cloudinary: ${response.statusCode}');
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        print('Dữ liệu phản hồi Cloudinary: $responseData');
        final data = json.decode(responseData);
        return data['secure_url'];
      } else {
        print('Upload thất bại: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Lỗi upload Cloudinary: $e');
      return null;
    }
  }

  Future<void> pickAndUploadImage() async {
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để thay đổi avatar!')),
        );
      }
      return;
    }

    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    final imageUrl = await uploadImageToCloudinary(file.bytes!, file.name);
    if (imageUrl != null && mounted) {
      await saveAvatarUrlToFirestore(imageUrl);
      setState(() {
        avatarUrl = imageUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật avatar thành công!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tải avatar thất bại!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ Sơ'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: pickAndUploadImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                    ? NetworkImage(avatarUrl!)
                    : const AssetImage('assets/images/avatar.jpg') as ImageProvider,
                child: (avatarUrl == null || avatarUrl!.isEmpty)
                    ? const Icon(Icons.camera_alt, color: Colors.white, size: 40)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              username ?? 'Đang tải...',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Bấm vào ảnh để thay đổi avatar',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {
                // Nâng cấp VIP
              },
              child: const Text('Nâng cấp VIP'),
            ),
          ),
          const SizedBox(height: 20),
          // CÁ NHÂN
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: const Text(
              'CÁ NHÂN',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text('Chỉnh sửa hồ sơ'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: Colors.orange),
            title: const Text('Nạp xu'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.blue),
            title: const Text('Thông báo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events, color: Colors.orangeAccent),
            title: const Text('Lịch sử nạp VIP'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.red),
            title: const Text('Danh sách chặn'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.purple),
            title: const Text('Cài đặt'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          // CỘNG ĐỒNG
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: const Text(
              'CỘNG ĐỒNG',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.purple),
            title: const Text('Cộng đồng Facebook'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.share, color: Colors.blue),
            title: const Text('Chia sẻ app'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          // KHÁC
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: const SizedBox(height: 1),
          ),
          ListTile(
            leading: const Icon(Icons.book, color: Colors.blue),
            title: const Text('Điều khoản và Điều kiện'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.shield, color: Colors.lightBlueAccent),
            title: const Text('Chính sách bảo mật'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Đăng xuất'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();
  String? gender;
  String? location;
  String? maritalStatus;
  String? bio;
  List<String> hobbies = [];
  String? birthDate;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    final uid = user?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            gender = data['gender'] as String? ?? '';
            location = data['location'] as String? ?? '';
            maritalStatus = data['maritalStatus'] as String? ?? '';
            bio = data['bio'] as String? ?? '';
            hobbies = List<String>.from(data['hobbies'] ?? []);
            birthDate = data['birthDate'] as String? ?? '';
          });
        }
      }
    } catch (e) {
      print('Lỗi tải dữ liệu hồ sơ: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tải dữ liệu hồ sơ thất bại: $e')),
        );
      }
    }
  }

  Future<void> saveProfileData() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = user?.uid;
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để cập nhật hồ sơ!')),
        );
      }
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'gender': gender,
        'location': location,
        'maritalStatus': maritalStatus,
        'bio': bio,
        'hobbies': hobbies,
        'birthDate': birthDate,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật hồ sơ thành công!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Lỗi lưu hồ sơ: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật hồ sơ thất bại: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void addHobby(String hobby) {
    if (hobby.isNotEmpty && !hobbies.contains(hobby)) {
      setState(() {
        hobbies.add(hobby);
      });
    }
  }

  void removeHobby(String hobby) {
    setState(() {
      hobbies.remove(hobby);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hobbyController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Giới tính
              DropdownButtonFormField<String>(
                value: gender?.isNotEmpty == true ? gender : null,
                decoration: const InputDecoration(labelText: 'Giới tính'),
                items: ['Nam', 'Nữ', 'Khác']
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    gender = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Nơi ở
              TextFormField(
                initialValue: location,
                decoration: const InputDecoration(labelText: 'Nơi ở'),
                onChanged: (value) {
                  location = value;
                },
              ),
              const SizedBox(height: 16),
              // Tình trạng
              DropdownButtonFormField<String>(
                value: maritalStatus?.isNotEmpty == true ? maritalStatus : null,
                decoration: const InputDecoration(labelText: 'Tình trạng'),
                items: ['Độc thân', 'Đã kết hôn', 'Đang hẹn hò']
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    maritalStatus = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Ngày sinh
              TextFormField(
                initialValue: birthDate,
                decoration: const InputDecoration(labelText: 'Ngày sinh (dd/mm/yyyy)'),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final RegExp dateRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
                    if (!dateRegex.hasMatch(value)) {
                      return 'Vui lòng nhập định dạng dd/mm/yyyy';
                    }
                  }
                  return null;
                },
                onChanged: (value) {
                  birthDate = value;
                },
              ),
              const SizedBox(height: 16),
              // Giới thiệu
              TextFormField(
                initialValue: bio,
                decoration: const InputDecoration(labelText: 'Giới thiệu'),
                maxLines: 4,
                onChanged: (value) {
                  bio = value;
                },
              ),
              const SizedBox(height: 16),
              // Sở thích
              const Text(
                'Sở thích',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: hobbies
                    .map((hobby) => Chip(
                          label: Text(hobby),
                          onDeleted: () => removeHobby(hobby),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: hobbyController,
                      decoration: const InputDecoration(labelText: 'Thêm sở thích'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      final hobby = hobbyController.text.trim();
                      if (hobby.isNotEmpty) {
                        addHobby(hobby);
                        hobbyController.clear();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Nút lưu
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: saveProfileData,
                      child: const Text('Lưu thay đổi'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}