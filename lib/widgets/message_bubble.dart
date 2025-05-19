import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget hiển thị một tin nhắn trong giao diện chat
class MessageBubble extends StatelessWidget {
  // Nội dung tin nhắn (có thể là null nếu chỉ gửi tệp)
  final String? message;

  // Tên người gửi
  final String sender;

  // Xác định tin nhắn có phải của người dùng hiện tại không
  final bool isMe;

  // Đường dẫn tới tệp đính kèm (nếu có)
  final String? fileUrl;

  // Kiểu tệp đính kèm (ví dụ: jpg, pdf, docx...)
  final String? fileType;

  // Constructor
  const MessageBubble({
    super.key,
    required this.message,
    required this.sender,
    required this.isMe,
    this.fileUrl,
    this.fileType,
  });

  /// Kiểm tra xem tệp có phải là hình ảnh không
  bool get isImage {
    final lower = fileType?.toLowerCase() ?? '';
    return ['jpg', 'jpeg', 'png', 'gif'].contains(lower);
  }

  /// Trả về màu nền của bong bóng tin nhắn dựa theo chế độ sáng/tối và người gửi
  Color getMessageBubbleColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isMe) {
      return Theme.of(context).colorScheme.primary.withOpacity(0.85);
    } else {
      return isDark ? Colors.grey[800]! : Colors.grey[300]!;
    }
  }

  /// Trả về màu chữ phù hợp với chế độ sáng/tối và người gửi
  Color getTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isMe) {
      return Colors.white;
    } else {
      return isDark ? Colors.white70 : Colors.black87;
    }
  }

  /// Hàm xây dựng widget UI
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Lấy theme hiện tại

    return Align(
      // Căn phải nếu là người dùng, căn trái nếu là người khác
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75, // Giới hạn độ rộng
        ),
        decoration: BoxDecoration(
          color: getMessageBubbleColor(context), // Màu nền
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
          boxShadow: isMe
              ? [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Hiển thị tên người gửi nếu không rỗng
            if (sender.isNotEmpty)
              Text(
                sender,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isMe ? Colors.white70 : theme.colorScheme.primary,
                ),
              ),

            if (sender.isNotEmpty) const SizedBox(height: 6),

            // Hiển thị nội dung văn bản nếu có
            if (message != null && message!.isNotEmpty)
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: getTextColor(context),
                ),
              ),

            // Hiển thị phần file đính kèm nếu có
            if (fileUrl != null) ...[
              const SizedBox(height: 10),

              // Nếu là hình ảnh
              isImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        fileUrl!,
                        width: 220,
                        height: 220,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return SizedBox(
                            width: 220,
                            height: 220,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Text('Không thể tải hình ảnh'),
                      ),
                    )

                  // Nếu không phải hình ảnh => Hiển thị nút tải file
                  : ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(fileUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.file_download),
                      label: const Text("Tải tệp"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: theme.colorScheme.onSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
