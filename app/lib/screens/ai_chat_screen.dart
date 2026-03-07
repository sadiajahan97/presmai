import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_history_drawer.dart';
import '../widgets/presmai_app_bar.dart';
import '../services/chat_service.dart';

class AiChatScreen extends StatefulWidget {
  final String? chatId;
  const AiChatScreen({super.key, this.chatId});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String? _currentChatId;
  String _chatTitle = 'PresMAI';

  @override
  void initState() {
    super.initState();
    _currentChatId = widget.chatId;
    if (_currentChatId != null) {
      _loadChatDetails();
      _loadMessages();
    }
  }

  @override
  void didUpdateWidget(AiChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chatId != oldWidget.chatId) {
      _currentChatId = widget.chatId;
      if (_currentChatId != null) {
        _loadChatDetails();
        _loadMessages();
      } else {
        setState(() {
          _messages = [];
          _chatTitle = 'PresMAI';
        });
      }
    }
  }

  Future<void> _loadChatDetails() async {
    if (_currentChatId == null) return;
    final chat = await _chatService.getChat(_currentChatId!);
    if (mounted && chat != null) {
      setState(() {
        _chatTitle = chat['name'] ?? 'PresMAI';
      });
    }
  }

  Future<void> _loadMessages() async {
    if (_currentChatId == null) return;
    setState(() {
      _isLoading = true;
    });
    final messages = await _chatService.listMessages(_currentChatId!);
    if (mounted) {
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSendMessage({String? filePath, List<int>? fileBytes, String? fileName}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && filePath == null && fileBytes == null) return;

    // If we don't have a chat ID yet, create one first
    if (_currentChatId == null) {
      String chatName = text.isNotEmpty ? (text.length > 20 ? text.substring(0, 20) : text) : "File Upload";
      final chatResult = await _chatService.createChat(name: chatName);
      if (chatResult['success']) {
        _currentChatId = chatResult['chat']['id'];
        _chatTitle = chatResult['chat']['name'] ?? chatName;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start chat')),
        );
        return;
      }
    }

    // Optimistic UI update
    String displayContent = text;
    if (displayContent.isEmpty) {
      displayContent = 'Sent a file: ${fileName ?? (filePath != null ? filePath.split('/').last : 'file')}';
    }

    final userMsg = {
      'role': 'user',
      'content': displayContent,
      'createdAt': DateTime.now().toIso8601String(),
    };

    setState(() {
      _messages.add(userMsg);
      if (text.isNotEmpty) _messageController.clear();
    });

    final result = await _chatService.sendMessage(
      _currentChatId!,
      text,
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: fileName,
    );

    if (result['success']) {
      _loadMessages();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to send message')),
        );
      }
    }
  }

  Future<void> _handleCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      final bytes = await photo.readAsBytes();
      _handleSendMessage(fileBytes: bytes, fileName: photo.name);
    }
  }

  Future<void> _handleImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      _handleSendMessage(fileBytes: bytes, fileName: image.name);
    }
  }

  Future<void> _handleFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.single.bytes != null) {
      _handleSendMessage(
        fileBytes: result.files.single.bytes,
        fileName: result.files.single.name,
      );
    } else if (result != null && result.files.single.path != null) {
      _handleSendMessage(
        filePath: result.files.single.path,
        fileName: result.files.single.name,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      drawer: ChatHistoryDrawer(selectedChatId: _currentChatId),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            PresmaiAppBar(
              title: _chatTitle,
              leading: Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.slate600),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
            ),

            // Chat area
            Expanded(
              child: _isLoading && _messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? _buildWelcomeState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            return Column(
                              children: [
                                ChatBubble(
                                  isUser: msg['role'] == 'user',
                                  message: msg['content'] ?? '',
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          },
                        ),
            ),

            // Input bar
            ChatInputBar(
              controller: _messageController,
              onSend: () => _handleSendMessage(),
              onCamera: _handleCamera,
              onImage: _handleImage,
              onFile: _handleFile,
            ),

            // Bottom nav
            BottomNavBar(
              currentTab: NavTab.chat,
              onTabSelected: (tab) => _navigateToTab(context, tab),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: AppColors.primary, size: 48),
          ),
          const SizedBox(height: 24),
          const Text(
            'How can I help you today?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'I can help with medication refills, dosage tracking, or general health questions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.slate500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToTab(BuildContext context, NavTab tab) {
    switch (tab) {
      case NavTab.home:
        Navigator.pushReplacementNamed(context, '/welcome');
        break;
      case NavTab.chat:
        break; // already here
      case NavTab.alerts:
        Navigator.pushReplacementNamed(context, '/alerts');
        break;
      case NavTab.archive:
        Navigator.pushReplacementNamed(context, '/archive');
        break;
    }
  }
}


