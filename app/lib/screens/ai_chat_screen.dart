import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_history_drawer.dart';
import '../widgets/presmai_app_bar.dart';

class AiChatScreen extends StatelessWidget {
  const AiChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      drawer: const ChatHistoryDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            PresmaiAppBar(
              leading: Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.slate600),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              trailing: Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.history, color: AppColors.slate600),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
            ),

            // Chat area
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Date label
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        'TODAY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: AppColors.slate400,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // AI message
                  const ChatBubble(
                    isUser: false,
                    message: "Hello! I'm here to help you manage your medications. I've noticed your Lipitor refill is due in 3 days. Would you like me to request a refill from your pharmacy now?",
                  ),
                  const SizedBox(height: 24),

                  // User message
                  const ChatBubble(
                    isUser: true,
                    message: 'Can you also check if my Vitamin D prescription has any remaining refills?',
                  ),
                  const SizedBox(height: 24),

                  // AI response
                  const ChatBubble(
                    isUser: false,
                    message: 'Checking your records... Yes, your Vitamin D3 (2000 IU) has 2 refills remaining at City Health Pharmacy.',
                  ),
                ],
              ),
            ),

            // Input bar
            const ChatInputBar(),

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
