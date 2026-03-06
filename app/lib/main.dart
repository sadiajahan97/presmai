import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/chat_history_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/archive_screen.dart';

void main() {
  runApp(const PresMAIApp());
}

class PresMAIApp extends StatelessWidget {
  const PresMAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PresMAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/chat': (context) => const AiChatScreen(),
        '/chat-history': (context) => const ChatHistoryScreen(),
        '/alerts': (context) => const AlertsScreen(),
        '/archive': (context) => const ArchiveScreen(),
      },
    );
  }
}
