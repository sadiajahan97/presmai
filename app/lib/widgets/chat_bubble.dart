import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../theme/app_colors.dart';
import './full_screen_image.dart';


class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final String? senderLabel;
  final String? filePath;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.senderLabel,
    this.filePath,
  });

  String _formatUrl(String path) {
    if (path.startsWith('http')) return path;
    // If it's an absolute local path, don't format it as a network URL
    if (path.startsWith('/') && !path.contains('/storage/')) return path;
    
    final baseUrl = dotenv.get('API_URL', fallback: 'http://localhost:8000');
    if (path.contains('/storage/')) {
      final parts = path.split('/storage/');
      return '$baseUrl/storage/${parts.last}';
    }
    return '$baseUrl/$path';
  }

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return _buildUserBubble(context);
    }
    return _buildAiBubble(context);
  }

  Widget _buildAiBubble(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Avatar
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryLight,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.smart_toy, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                senderLabel ?? 'PRESMAI ASSISTANT',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(0),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(color: AppColors.slate100),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.slate200.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (filePath != null) _buildAttachmentPreview(context, filePath!),
                    if (message.isNotEmpty)
                      MarkdownBody(
                        data: message,
                        styleSheet: MarkdownStyleSheet(
                          p: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.6,
                            color: AppColors.slate800,
                          ),
                          strong: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate900,
                          ),
                          listBullet: GoogleFonts.manrope(
                            fontSize: 14,
                            color: AppColors.slate800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48), // right margin
      ],
    );
  }

  Widget _buildUserBubble(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 48), // left margin
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(0),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
                child: Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (filePath != null) _buildAttachmentPreview(context, filePath!),
                    if (message.isNotEmpty)
                      MarkdownBody(
                        data: message,
                        styleSheet: MarkdownStyleSheet(
                          p: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.6,
                            color: isUser ? AppColors.white : AppColors.slate800,
                          ),
                          strong: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            color: isUser ? AppColors.white : AppColors.slate900,
                          ),
                          listBullet: GoogleFonts.manrope(
                            fontSize: 14,
                            color: isUser ? AppColors.white : AppColors.slate800,
                          ),
                        ),
                      ),
                  ],
                ),
          ),
        ),
      ],
    );
  }


  Future<void> _handleOpenAttachment(BuildContext context, String path) async {
    final String url = _formatUrl(path);
    final bool isNetwork = url.startsWith('http');

    try {
      String localPath = url;

      if (isNetwork) {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Opening file...'),
              ],
            ),
            duration: Duration(seconds: 1),
          ),
        );

        final directory = await getTemporaryDirectory();
        final fileName = url.split('/').last;
        localPath = '${directory.path}/$fileName';

        // Check if already downloaded
        if (!await File(localPath).exists()) {
          await Dio().download(url, localPath);
        }
      } else {
        // If it's a local file (optimistic state), check if it exists
        if (!await File(localPath).exists()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Local file no longer available')),
          );
          return;
        }
      }

      final result = await OpenFilex.open(localPath);
      if (result.type != ResultType.done) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open file: ${result.message}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')),
        );
      }
    }
  }

  Widget _buildAttachmentPreview(BuildContext context, String path) {
    final String url = _formatUrl(path);
    final bool isLocal = url.startsWith('/') && !url.contains('http');
    final String extension = path.split('.').last.toLowerCase();
    final bool isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(extension);

    if (!isImage) return _buildFileAttachment(context, path);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImage(
              imageUrl: url,
              isLocal: isLocal,
            ),
          ),
        );
      },

      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: isLocal && !kIsWeb
              ? Image.file(
                  File(url),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
                )
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
                ),
        ),
      ),
    );
  }

  Widget _buildFileAttachment(BuildContext context, String path) {
    String fileName = path.split('/').last;
    
    // Strip prefix (e.g. user_id_ or uuid_) if it exists
    if (fileName.contains('_')) {
      final parts = fileName.split('_');
      // Strip everything before the first underscore to show original name
      fileName = parts.skip(1).join('_');
    }
    
    return GestureDetector(
      onTap: () => _handleOpenAttachment(context, path),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isUser ? Colors.white24 : AppColors.slate50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isUser ? Colors.white30 : AppColors.slate200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, color: isUser ? Colors.white : AppColors.slate500, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isUser ? Colors.white : AppColors.slate900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorImage() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: isUser ? Colors.white24 : AppColors.slate100,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image, color: isUser ? Colors.white : AppColors.slate500, size: 20),
          const SizedBox(width: 8),
          Text(
            'Failed to load image',
            style: TextStyle(color: isUser ? Colors.white : AppColors.slate500, fontSize: 12),
          ),
        ],
      ),
    );
  }

}
