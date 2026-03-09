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

  String _formatDateTime(String createdAt) {
    try {
      final dateTime = DateTime.parse(createdAt).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final month = months[dateTime.month - 1];
      final day = dateTime.day;
      final year = dateTime.year;
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
      
      return '$day $month, $year    $hour:$minute $amPm';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            children: [
                              // Medication Alerts section
                              _sectionTitle('Medication Alerts'),
                              ..._notifications.map((notification) {
                                return AlertTile(
                                  icon: Icons.alarm,
                                  title: notification['content'] ?? '',
                                  subtitle: _formatDateTime(notification['createdAt'] ?? ''),
                                );
                              }).toList(),
                            ],
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
          color: AppColors.primary,
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
