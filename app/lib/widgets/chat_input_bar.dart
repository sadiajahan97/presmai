import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController? controller;
  final VoidCallback? onSend;
  final VoidCallback? onCamera;
  final VoidCallback? onImage;
  final VoidCallback? onFile;
  final PlatformFile? selectedFile;
  final VoidCallback? onRemoveFile;

  const ChatInputBar({
    super.key,
    this.controller,
    this.onSend,
    this.onCamera,
    this.onImage,
    this.onFile,
    this.selectedFile,
    this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.slate100, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedFile != null) _buildFilePreview(),
          Row(
            children: [
              // Camera & Image buttons
              Theme(
                data: Theme.of(context).copyWith(
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: PopupMenuButton<String>(
                  offset: const Offset(0, -170),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: AppColors.white,
                  elevation: 4,
                  shadowColor: AppColors.slate200.withOpacity(0.5),
                  itemBuilder: (context) => [
                    _buildPopupItem(Icons.photo_camera_outlined, 'Camera', 'camera'),
                    _buildPopupItem(Icons.image_outlined, 'Photos', 'photos'),
                    _buildPopupItem(Icons.attach_file_outlined, 'Files', 'files'),
                  ],
                  onSelected: (value) {
                    if (value == 'camera') onCamera?.call();
                    if (value == 'photos') onImage?.call();
                    if (value == 'files') onFile?.call();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.add, color: AppColors.slate500, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Text input
              Expanded(
                child: TextField(
                  controller: controller,
                  cursorColor: AppColors.slate900,
                  textAlignVertical: TextAlignVertical.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate900,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask PresMAI anything...',
                    hintStyle: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate400,
                    ),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    constraints: const BoxConstraints(minHeight: 48, maxHeight: 48),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.slate200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.slate200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Send button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryShadow,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: onSend,
                  icon: const Icon(Icons.send, color: AppColors.white),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview() {
    final bool isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(selectedFile!.extension?.toLowerCase());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 40,
              height: 40,
              color: AppColors.slate200,
              child: isImage && !kIsWeb && selectedFile!.path != null
                  ? Image.file(File(selectedFile!.path!), fit: BoxFit.cover)
                  : isImage && kIsWeb && selectedFile!.bytes != null
                      ? Image.memory(selectedFile!.bytes!, fit: BoxFit.cover)
                      : const Icon(Icons.description, color: AppColors.slate500),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedFile!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate900,
                  ),
                ),
                Text(
                  '${(selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemoveFile,
            icon: const Icon(Icons.close, size: 18, color: AppColors.slate500),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }


  PopupMenuItem<String> _buildPopupItem(IconData icon, String text, String value) {
    return PopupMenuItem<String>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: AppColors.slate500),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _HoverIconButton({required this.icon, this.onPressed});

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: IconButton(
        onPressed: widget.onPressed,
        icon: Icon(widget.icon, size: 22),
        color: _isHovered ? AppColors.primary : AppColors.slate500,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
    );
  }
}
