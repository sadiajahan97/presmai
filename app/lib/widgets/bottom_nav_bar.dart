import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum NavTab { home, chat, alerts, archive }

class BottomNavBar extends StatelessWidget {
  final NavTab currentTab;
  final ValueChanged<NavTab> onTabSelected;

  const BottomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.slate100, width: 1),
        ),
      ),
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 28),
      child: Row(
        children: NavTab.values.map((tab) {
          final isActive = tab == currentTab;
          return Expanded(
            child: _NavItem(
              icon: _iconForTab(tab),
              label: _labelForTab(tab),
              isActive: isActive,
              onTap: () => onTabSelected(tab),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _iconForTab(NavTab tab) {
    switch (tab) {
      case NavTab.home:
        return Icons.home_outlined;
      case NavTab.chat:
        return Icons.chat_bubble_outline;
      case NavTab.alerts:
        return Icons.notifications_outlined;
      case NavTab.archive:
        return Icons.inventory_2_outlined;
    }
  }

  String _labelForTab(NavTab tab) {
    switch (tab) {
      case NavTab.home:
        return 'Home';
      case NavTab.chat:
        return 'Chat';
      case NavTab.alerts:
        return 'Alerts';
      case NavTab.archive:
        return 'Archive';
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.slate400;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              height: 2,
              width: 40,
              color: AppColors.primary,
            ),
          Icon(
            isActive ? _filledIcon : icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData get _filledIcon {
    switch (label) {
      case 'Home':
        return Icons.home;
      case 'Chat':
        return Icons.chat_bubble;
      case 'Alerts':
        return Icons.notifications;
      case 'Archive':
        return Icons.archive;
      default:
        return icon;
    }
  }
}
