import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math' as math;
import '../theme/app_colors.dart';
import '../widgets/alert_tile.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/presmai_app_bar.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final NotificationService _notificationService = NotificationService();
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _isRoutineLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final notifications = await _notificationService.getNotifications();
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  Future<List<dynamic>> _fetchMedicationsApi() async {
    final auth = AuthService();
    final token = await auth.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final baseUrl = dotenv.get('API_URL', fallback: 'http://localhost:8000');
    final uri = Uri.parse('$baseUrl/prescriptions/medications');

    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Fetch medications failed (${res.statusCode}): ${res.body}');
    }

    final data = jsonDecode(res.body);
    if (data is List) return data;
    return [];
  }

  String _getDateHeader(String? createdAt) {
    if (createdAt == null) return 'Unknown Date';
    try {
      final dateTime = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now().toLocal();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final notificationDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (notificationDate == today) {
        return 'Today';
      } else if (notificationDate == yesterday) {
        return 'Yesterday';
      } else {
        final months = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
      }
    } catch (e) {
      return 'Unknown Date';
    }
  }

  String _formatTime(String createdAt) {
    try {
      final dateTime = DateTime.parse(createdAt).toLocal();
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
      
      return '$hour:$minute $amPm';
    } catch (e) {
      return '';
    }
  }

  Map<String, List<Map<String, dynamic>>> _getGroupedNotifications() {
    final sorted = List<Map<String, dynamic>>.from(_notifications);
    sorted.sort((a, b) {
      final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(0);
      final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(0);
      return dateB.compareTo(dateA);
    });

    final groups = <String, List<Map<String, dynamic>>>{};
    for (var notification in sorted) {
      final header = _getDateHeader(notification['createdAt']);
      if (!groups.containsKey(header)) {
        groups[header] = [];
      }
      groups[header]!.add(notification);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groupedNotifications = _getGroupedNotifications();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            PresmaiAppBar(
              title: 'Alerts',
              centerTitle: true,
              leading: SizedBox(
                height: 44,
                child: TextButton(
                  onPressed: _isRoutineLoading
                      ? null
                      : () async {
                          setState(() => _isRoutineLoading = true);
                          try {
                            final medications = await _fetchMedicationsApi();
                            if (!mounted) return;
                            final updated = await Navigator.of(context).pushNamed(
                              '/medication-routine',
                              arguments: medications,
                            );
                            if (updated == true) {
                              await _fetchNotifications();
                            }
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Routine failed: $e')),
                            );
                          } finally {
                            if (!mounted) return;
                            setState(() => _isRoutineLoading = false);
                          }
                        },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isRoutineLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.medication_outlined,
                                color: AppColors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Routine',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              trailing: _buildScanPrescriptionMenu(),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _notifications.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'No alerts yet',
                                  style: GoogleFonts.manrope(
                                    color: AppColors.slate900,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tap "Scan" to scan a prescription and start getting medication alerts.',
                                  style: GoogleFonts.manrope(
                                    color: AppColors.slate500,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchNotifications,
                          child: ListView(
                            padding: const EdgeInsets.only(bottom: 16),
                            children: groupedNotifications.entries.expand((entry) {
                              return [
                                _sectionTitle(entry.key),
                                ...entry.value.map((notification) {
                                  return AlertTile(
                                    icon: Icons.alarm,
                                    title: notification['content'] ?? '',
                                    subtitle: _formatTime(notification['createdAt'] ?? ''),
                                  );
                                }),
                              ];
                            }).toList(),
                          ),
                        ),
            ),

            // Bottom nav
            BottomNavBar(
              currentTab: NavTab.alerts,
              onTabSelected: (tab) => _navigateToTab(context, tab),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppColors.slate500,
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
        break;
      case NavTab.archive:
        Navigator.pushReplacementNamed(context, '/archive');
        break;
      case NavTab.profile:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  Widget _buildScanPrescriptionMenu() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.white,
      elevation: 4,
      shadowColor: AppColors.slate200.withValues(alpha: 0.5),
      itemBuilder: (context) => [
        _buildPopupItem(Icons.photo_camera_outlined, 'Camera', 'camera'),
        _buildPopupItem(Icons.image_outlined, 'Photos', 'photos'),
        _buildPopupItem(Icons.attach_file_outlined, 'Files', 'files'),
      ],
      onSelected: (value) {
        // Do not await here; PopupMenuButton expects a synchronous callback.
        _handleScanOption(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner_outlined, color: AppColors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'Scan',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleScanOption(String value) {
    switch (value) {
      case 'camera':
        _handleCamera();
        break;
      case 'photos':
        _handleImage();
        break;
      case 'files':
        _handleFile();
        break;
    }
  }

  PopupMenuItem<String> _buildPopupItem(IconData icon, String text, String value) {
    return PopupMenuItem<String>(
      value: value,
      padding: EdgeInsets.zero,
      child: _HoverPopupItem(icon: icon, text: text),
    );
  }

  Future<void> _handleCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    final bytes = await photo.readAsBytes();
    if (!mounted) return;

    await _showScanPreviewDialog(
      fileBytes: bytes,
      imageBytes: bytes,
      fileName: photo.name,
      fileSizeBytes: bytes.length,
      mimeType: _guessMimeType(photo.name),
      pickerLabel: 'Camera',
    );
  }

  Future<void> _handleImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;

    await _showScanPreviewDialog(
      fileBytes: bytes,
      imageBytes: bytes,
      fileName: image.name,
      fileSizeBytes: bytes.length,
      mimeType: _guessMimeType(image.name),
      pickerLabel: 'Photos',
    );
  }

  Future<void> _handleFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final name = file.name;
    final sizeBytes = file.size;
    final lowerName = name.toLowerCase();
    final ext = lowerName.contains('.') ? lowerName.split('.').last : lowerName;

    final isImage = <String>{'jpg', 'jpeg', 'png', 'gif', 'webp'}.contains(ext);
    final Uint8List? bytes = file.bytes;

    if (!mounted) return;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read the selected file bytes.')),
      );
      return;
    }

    await _showScanPreviewDialog(
      fileBytes: bytes,
      imageBytes: isImage ? bytes : null,
      fileName: name,
      fileSizeBytes: sizeBytes,
      mimeType: _guessMimeType(name),
      pickerLabel: 'Files',
    );
  }

  String _guessMimeType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  Future<List<dynamic>> _scanPrescriptionApi({
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
  }) async {
    final auth = AuthService();
    final token = await auth.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final baseUrl = dotenv.get('API_URL', fallback: 'http://localhost:8000');
    final uri = Uri.parse('$baseUrl/prescriptions/scan');

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    // Backend expects multipart field name `file`.
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Scan failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);
    if (data is Map<String, dynamic>) {
      final meds = data['medications'];
      if (meds is List) return meds;
    }
    return [];
  }

  Future<void> _updateMedicationApi({
    required String medicationId,
    required String name,
    required String? strength,
    required bool morning,
    required bool afternoon,
    required bool night,
    required int days,
  }) async {
    final auth = AuthService();
    final token = await auth.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final baseUrl = dotenv.get('API_URL', fallback: 'http://localhost:8000');
    final uri = Uri.parse('$baseUrl/prescriptions/medications/$medicationId');

    final res = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'strength': strength,
        'morning': morning,
        'afternoon': afternoon,
        'night': night,
        'days': days,
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Update failed (${res.statusCode}): ${res.body}');
    }
  }

  Future<void> _showMedicationRoutineDialog(List<dynamic> medications) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final meds = medications
            .where((m) => m is Map<String, dynamic>)
            .map((m) => Map<String, dynamic>.from(m as Map<String, dynamic>))
            .toList();

        final editedNames =
            List<String>.generate(meds.length, (i) => meds[i]['name']?.toString() ?? '');
        final editedStrengths = List<String>.generate(
          meds.length,
          (i) => meds[i]['strength']?.toString() ?? '',
        );
        final editedDays =
            List<String>.generate(meds.length, (i) => meds[i]['days']?.toString() ?? '0');
        final editedMorning =
            List<bool>.generate(meds.length, (i) => meds[i]['morning'] == true);
        final editedAfternoon =
            List<bool>.generate(meds.length, (i) => meds[i]['afternoon'] == true);
        final editedNight =
            List<bool>.generate(meds.length, (i) => meds[i]['night'] == true);
        bool isUpdatingAll = false;

        final hasMeds = meds.isNotEmpty;

        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Medication Routine',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
          ),
          content: hasMeds
              ? SizedBox(
                  width: double.maxFinite,
                  child: StatefulBuilder(
                    builder: (context, setDialogState) {
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Medication')),
                                  DataColumn(label: Text('Strength')),
                                  DataColumn(label: Text('Morning')),
                                  DataColumn(label: Text('Afternoon')),
                                  DataColumn(label: Text('Night')),
                                  DataColumn(label: Text('Days')),
                                ],
                                rows: List.generate(meds.length, (i) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        SizedBox(
                                          width: 180,
                                          child: TextFormField(
                                            key: ValueKey('med_name_$i'),
                                            initialValue: editedNames[i],
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 10,
                                              ),
                                            ),
                                            onChanged: (v) => setDialogState(
                                              () => editedNames[i] = v,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 140,
                                          child: TextFormField(
                                            key: ValueKey('med_strength_$i'),
                                            initialValue: editedStrengths[i],
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 10,
                                              ),
                                            ),
                                            onChanged: (v) => setDialogState(
                                              () => editedStrengths[i] = v,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Checkbox(
                                          value: editedMorning[i],
                                          onChanged: (v) {
                                            setDialogState(() {
                                              editedMorning[i] = v ?? false;
                                            });
                                          },
                                        ),
                                      ),
                                      DataCell(
                                        Checkbox(
                                          value: editedAfternoon[i],
                                          onChanged: (v) {
                                            setDialogState(() {
                                              editedAfternoon[i] = v ?? false;
                                            });
                                          },
                                        ),
                                      ),
                                      DataCell(
                                        Checkbox(
                                          value: editedNight[i],
                                          onChanged: (v) {
                                            setDialogState(() {
                                              editedNight[i] = v ?? false;
                                            });
                                          },
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 90,
                                          child: TextFormField(
                                            key: ValueKey('med_days_$i'),
                                            initialValue: editedDays[i],
                                            keyboardType:
                                                TextInputType.number,
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 10,
                                              ),
                                            ),
                                            onChanged: (v) => setDialogState(
                                              () => editedDays[i] = v,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isUpdatingAll
                                    ? null
                                    : () async {
                                        // Preflight validation: no API calls if any row is invalid.
                                        for (var i = 0; i < meds.length; i++) {
                                          final rowNum = i + 1;
                                          final medicationId =
                                              meds[i]['id']?.toString() ?? '';
                                          final name =
                                              editedNames[i].trim();
                                          final strengthRaw =
                                              editedStrengths[i].trim();
                                          final strength = strengthRaw.isEmpty
                                              ? null
                                              : strengthRaw;
                                          final daysRaw =
                                              editedDays[i].trim();
                                          final days = int.tryParse(daysRaw);
                                          final morning = editedMorning[i];
                                          final afternoon = editedAfternoon[i];
                                          final night = editedNight[i];
                                          final anyTime =
                                              morning || afternoon || night;

                                          if (medicationId.isEmpty) {
                                            ScaffoldMessenger.of(dialogContext)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Row $rowNum: Medication id is missing.',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          if (name.isEmpty) {
                                            ScaffoldMessenger.of(dialogContext)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Row $rowNum: Medication name is required.',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          if (days == null || days < 0) {
                                            ScaffoldMessenger.of(dialogContext)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Row $rowNum: Days must be a number >= 0.',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          if (!anyTime) {
                                            ScaffoldMessenger.of(dialogContext)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Row $rowNum: Select at least one time (Morning/Afternoon/Night).',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          // strength can be null/empty; no additional validation needed.
                                        }

                                        setDialogState(() {
                                          isUpdatingAll = true;
                                        });
                                        try {
                                          for (var i = 0; i < meds.length; i++) {
                                            final medicationId =
                                                meds[i]['id']?.toString() ??
                                                    '';
                                            final name =
                                                editedNames[i].trim();
                                            final strengthRaw =
                                                editedStrengths[i].trim();
                                            final strength = strengthRaw.isEmpty
                                                ? null
                                                : strengthRaw;
                                            final days =
                                                int.parse(editedDays[i].trim());

                                            await _updateMedicationApi(
                                              medicationId: medicationId,
                                              name: name,
                                              strength: strength,
                                              morning: editedMorning[i],
                                              afternoon: editedAfternoon[i],
                                              night: editedNight[i],
                                              days: days,
                                            );
                                          }

                                          if (!dialogContext.mounted) return;
                                          ScaffoldMessenger.of(dialogContext)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Medication routine updated successfully.',
                                              ),
                                            ),
                                          );
                                          await _fetchNotifications();
                                        } catch (e) {
                                          if (!dialogContext.mounted) return;
                                          ScaffoldMessenger.of(dialogContext)
                                              .showSnackBar(
                                            SnackBar(
                                              content:
                                                  Text('Update failed: $e'),
                                            ),
                                          );
                                          return;
                                        } finally {
                                          if (!dialogContext.mounted) return;
                                          setDialogState(() {
                                            isUpdatingAll = false;
                                          });
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.slate900,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                child: isUpdatingAll
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.black,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'Update Routine',
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              : Text(
                  'No medications found in the prescription.',
                  style: GoogleFonts.manrope(color: AppColors.slate500),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: Text(
                'OK',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    final i = ((math.log(bytes) / math.log(1024)).floor()).clamp(0, suffixes.length - 1);
    final value = bytes / math.pow(1024, i);
    return '${value.toStringAsFixed(i == 0 ? 0 : 1)} ${suffixes[i]}';
  }

  Future<void> _showScanPreviewDialog({
    required Uint8List fileBytes,
    required Uint8List? imageBytes,
    required String fileName,
    required int fileSizeBytes,
    required String mimeType,
    required String pickerLabel,
  }) async {
    final bool isImage = imageBytes != null;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Preview ($pickerLabel)',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isImage)
                      GestureDetector(
                        onTap: () {
                          Navigator.of(dialogContext).push(
                            MaterialPageRoute(
                              builder: (screenContext) {
                                return Scaffold(
                                  backgroundColor: Colors.black,
                                  body: Stack(
                                    children: [
                                      Center(
                                        child: InteractiveViewer(
                                          clipBehavior: Clip.none,
                                          minScale: 0.5,
                                          maxScale: 4.0,
                                          child: Image.memory(
                                            imageBytes!,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top:
                                            MediaQuery.of(screenContext).padding.top + 10,
                                        left: 20,
                                        child: GestureDetector(
                                          onTap: () =>
                                              Navigator.of(screenContext).pop(),
                                          child: Container(
                                            padding:
                                                const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                  alpha: 0.5),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 24,
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
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            imageBytes,
                            width: 240,
                            height: 240,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 240,
                        height: 160,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.slate200),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.picture_as_pdf_outlined,
                              color: AppColors.primary,
                              size: 44,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Selected file',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 14),
                    Text(
                      fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatBytes(fileSizeBytes),
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  setState(() => isLoading = true);
                                  try {
                                    final medications =
                                        await _scanPrescriptionApi(
                                      fileBytes: fileBytes,
                                      fileName: fileName,
                                      mimeType: mimeType,
                                    );
                                    if (!dialogContext.mounted) return;
                                    Navigator.of(dialogContext).pop();
                                    if (!mounted) return;
                                    final updated = await Navigator.of(context)
                                        .pushNamed(
                                      '/medication-routine',
                                      arguments: medications,
                                    );
                                    if (!mounted) return;
                                    if (updated == true) {
                                      await _fetchNotifications();
                                    }
                                  } catch (e) {
                                    if (dialogContext.mounted) {
                                      ScaffoldMessenger.of(dialogContext)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Scan failed: $e'),
                                        ),
                                      );
                                    }
                                    setState(() => isLoading = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 40),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Confirm',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.of(dialogContext).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.slate900,
                            backgroundColor: AppColors.slate200,
                            side: BorderSide(color: AppColors.slate300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 40),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _HoverPopupItem extends StatefulWidget {
  final IconData icon;
  final String text;

  const _HoverPopupItem({required this.icon, required this.text});

  @override
  State<_HoverPopupItem> createState() => _HoverPopupItemState();
}

class _HoverPopupItemState extends State<_HoverPopupItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.slate50 : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              widget.icon,
              size: 20,
              color: _isHovered ? AppColors.primary : AppColors.slate500,
            ),
            const SizedBox(width: 12),
            Text(
              widget.text,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _isHovered ? AppColors.primary : AppColors.slate900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
