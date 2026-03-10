import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/folder_tile.dart';
import '../widgets/presmai_app_bar.dart';
import 'dart:math' as Math; // Required for Math.log and Math.pow
import '../services/storage_service.dart'; // Assuming this path for StorageService
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/full_screen_image.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final StorageService _storageService = StorageService();
  List<Map<String, dynamic>> _files = [];
  bool _isLoading = true;
  String _currentPath = ""; // Path relative to storage/user_id

  @override
  void initState() {
    super.initState();
    _fetchFiles();
  }

  Future<void> _fetchFiles() async {
    setState(() => _isLoading = true);
    final files = await _storageService.listFiles(folder: _currentPath);
    setState(() {
      _files = files;
      _isLoading = false;
    });
  }

  String _formatDate(String isoDate) {
    try {
      final dateTime = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now().toLocal();
      final diff = now.difference(dateTime);

      if (diff.inDays == 0) {
        if (diff.inHours == 0) {
          final mins = diff.inMinutes;
          return 'Modified $mins ${mins == 1 ? 'min' : 'mins'} ago';
        }
        final hours = diff.inHours;
        return 'Modified $hours ${hours == 1 ? 'hour' : 'hours'} ago';
      } else if (diff.inDays < 7) {
        final days = diff.inDays;
        return 'Modified $days ${days == 1 ? 'day' : 'days'} ago';
      } else {
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return 'Modified ${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (Math.log(bytes) / Math.log(1024)).floor();
    return ((bytes / Math.pow(1024, i)).toStringAsFixed(1)) + ' ' + suffixes[i];
  }

  String _getCleanName(String name) {
    if (name.contains('_')) {
      final parts = name.split('_');
      // Strip the first part regardless of length if it matches the prefix pattern
      return parts.skip(1).join('_');
    }
    return name;
  }

  IconData _getFileIcon(String name, bool isDir) {
    if (isDir) return Icons.folder_outlined;
    final lowerName = name.toLowerCase();
    if (lowerName.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
    if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg') || lowerName.endsWith('.png')) {
      return Icons.image_outlined;
    }
    if (lowerName.endsWith('.doc') || lowerName.endsWith('.docx')) return Icons.description_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Future<void> _showNewFolderDialog() async {
    final TextEditingController controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'New Folder',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Folder Name',
              hintStyle: GoogleFonts.manrope(color: AppColors.slate400),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.slate500,
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith<Color?>(
                  (states) => states.contains(WidgetState.hovered)
                      ? AppColors.slate100
                      : null,
                ),
              ),
              child: Text('Cancel', style: GoogleFonts.manrope()),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  final success = await _storageService.createFolder(name, currentFolder: _currentPath);
                  if (success && mounted) {
                    Navigator.pop(context);
                    _fetchFiles();
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to create folder')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.slate900,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Create', 
                style: GoogleFonts.manrope(color: AppColors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatUrl(String path) {
    if (path.startsWith('http')) return path;
    if (path.startsWith('/') && !path.contains('/storage/')) return path;
    
    final baseUrl = dotenv.get('API_URL', fallback: 'http://localhost:8000');
    if (path.contains('/storage/')) {
      final parts = path.split('/storage/');
      return '$baseUrl/storage/${parts.last}';
    }
    return '$baseUrl/$path';
  }

  Future<void> _handleOpenFile(BuildContext context, String path) async {
    final String url = _formatUrl(path);
    final bool isNetwork = url.startsWith('http');

    try {
      String localPath = url;

      if (isNetwork) {
        // Show loading indicator
        if (context.mounted) {
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
        }

        final directory = await getTemporaryDirectory();
        final fileName = url.split('/').last;
        localPath = '${directory.path}/$fileName';

        // Check if already downloaded
        if (!await File(localPath).exists()) {
          await Dio().download(url, localPath);
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

  Future<void> _handleUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        final success = await _storageService.uploadFile(result.files.single.path!, currentFolder: _currentPath);
        if (success && mounted) {
          _fetchFiles();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File uploaded successfully')),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _goBack() {
    if (_currentPath.isEmpty) return;
    final parts = _currentPath.split('/');
    parts.removeLast();
    setState(() {
      _currentPath = parts.join('/');
    });
    _fetchFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            PresmaiAppBar(
              title: _currentPath.isEmpty ? 'Archive' : _currentPath.split('/').last,
              leading: _currentPath.isNotEmpty ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.slate900),
                onPressed: _goBack,
              ) : null,
            ),

            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchFiles,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Action buttons row
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showNewFolderDialog,
                              icon: const Icon(Icons.create_new_folder, color: AppColors.white),
                              label: Text(
                                'New Folder',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.slate900,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                shadowColor: AppColors.primaryShadow,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _handleUpload,
                              icon: const Icon(Icons.upload_file, color: AppColors.primary),
                              label: Text(
                                'Upload',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
                                minimumSize: const Size(double.infinity, 56),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                              ).copyWith(
                                overlayColor: WidgetStateProperty.resolveWith<Color?>(
                                  (states) => states.contains(WidgetState.hovered)
                                      ? AppColors.primary.withValues(alpha: 0.08)
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),


                      // File list
                      if (_isLoading)
                        const Center(child: Padding(
                          padding: EdgeInsets.only(top: 32.0),
                          child: CircularProgressIndicator(),
                        ))
                      else if (_files.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 32.0),
                            child: Text(
                              'No documents found',
                              style: GoogleFonts.manrope(
                                color: AppColors.slate500,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._files.map((file) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: FolderTile(
                              icon: _getFileIcon(file['name'], file['is_dir']),
                              name: _getCleanName(file['name']),
                              modifiedDate: _formatDate(file['modified_at']),
                              itemCount: file['is_dir'] ? 'Folder' : _formatSize(file['size']),
                              onTap: () {
                                if (file['is_dir']) {
                                  setState(() {
                                    if (_currentPath.isEmpty) {
                                      _currentPath = file['name'];
                                    } else {
                                      _currentPath = '$_currentPath/${file['name']}';
                                    }
                                  });
                                  _fetchFiles();
                                  return;
                                }
                                
                                final name = file['name'].toString().toLowerCase();
                                final isImage = name.endsWith('.jpg') || 
                                              name.endsWith('.jpeg') || 
                                              name.endsWith('.png') || 
                                              name.endsWith('.gif');
                                
                                if (isImage) {
                                  final url = _formatUrl(file['path']);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FullScreenImage(
                                        imageUrl: url,
                                        isLocal: url.startsWith('/') && !url.contains('http'),
                                      ),
                                    ),
                                  );
                                } else {
                                  _handleOpenFile(context, file['path']);
                                }
                              },
                            ),
                          );
                        }).toList(),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom nav
            BottomNavBar(
              currentTab: NavTab.archive,
              onTabSelected: (tab) => _navigateToTab(context, tab),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTab(BuildContext context, NavTab tab) {
    switch (tab) {
      case NavTab.chat:
        Navigator.pushReplacementNamed(context, '/chat');
        break;
      case NavTab.alerts:
        Navigator.pushReplacementNamed(context, '/alerts');
        break;
      case NavTab.archive:
        break;
      case NavTab.profile:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }
}
