import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/alert_tile.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/presmai_app_bar.dart';
import '../services/notification_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

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
            const PresmaiAppBar(
              title: 'Alerts',
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _notifications.isEmpty
                      ? Center(
                          child: Text(
                            'No notifications yet',
                            style: GoogleFonts.manrope(
                              color: AppColors.slate500,
                              fontSize: 16,
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
}
