import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/alert_tile.dart';
import '../widgets/bottom_nav_bar.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                border: Border(bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.1))),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.slate900),
                  ),
                  Expanded(
                    child: Text(
                      'Alerts',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // balance
                ],
              ),
            ),

            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.5),
                border: Border(bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.1))),
              ),
              child: Row(
                children: [
                  _buildTab('All', 0),
                  _buildTab('Unread', 1),
                  _buildTab('Important', 2),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Refill Reminders section
                    _sectionTitle('Refill Reminders'),
                    AlertTile(
                      icon: Icons.medication_outlined,
                      title: 'Lipitor refill due in 2 days',
                      subtitle: '2 hours ago',
                      trailing: AlertActionButton(label: 'Request'),
                    ),

                    // Medication Alerts section
                    const SizedBox(height: 16),
                    _sectionTitle('Medication Alerts'),
                    AlertTile(
                      icon: Icons.alarm,
                      title: 'Take Vitamin D now',
                      subtitle: 'Just now',
                      trailing: AlertActionButton(label: 'Done', filled: false),
                    ),
                    AlertTile(
                      icon: Icons.medication,
                      title: 'Evening Metformin Dose',
                      subtitle: 'In 45 minutes',
                    ),

                    // System Updates section
                    const SizedBox(height: 16),
                    _sectionTitle('System Updates'),
                    AlertTile(
                      icon: Icons.security,
                      title: 'New login detected',
                      subtitle: 'Yesterday, 10:45 PM',
                      trailing: GestureDetector(
                        onTap: () {},
                        child: const Icon(Icons.close, color: AppColors.slate400, size: 20),
                      ),
                    ),
                    AlertTile(
                      icon: Icons.system_update,
                      title: 'PresMAI v2.4 Available',
                      subtitle: '2 days ago',
                      trailing: AlertActionButton(label: 'Update', filled: false, outlined: true),
                    ),
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

  Widget _buildTab(String label, int index) {
    final isActive = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.slate500,
            ),
          ),
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
      case NavTab.home:
        Navigator.pushReplacementNamed(context, '/welcome');
        break;
      case NavTab.chat:
        Navigator.pushReplacementNamed(context, '/chat');
        break;
      case NavTab.alerts:
        break;
      case NavTab.archive:
        Navigator.pushReplacementNamed(context, '/archive');
        break;
    }
  }
}
