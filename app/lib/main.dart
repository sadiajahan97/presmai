import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/archive_screen.dart';
import 'screens/profile_screen.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");

  // Persisted auth + route restore so hot restart lands on the same screen.
  final prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString('access_token');
  final lastRoute = prefs.getString('last_route');
  final initialRoute = _chooseInitialRoute(
    accessToken: accessToken,
    lastRoute: lastRoute,
  );
  
  // Request notification permissions
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(PresMAIApp(
    initialRoute: initialRoute,
    prefs: prefs,
  ));
}

const Set<String> _signedInRoutes = <String>{'/chat', '/alerts', '/archive', '/profile'};
const String _signedOutInitialRoute = '/welcome';
const String _signedInFallbackRoute = '/chat';

String _chooseInitialRoute({
  required String? accessToken,
  required String? lastRoute,
}) {
  final isSignedIn = accessToken != null && accessToken.isNotEmpty;
  if (!isSignedIn) return _signedOutInitialRoute;

  if (lastRoute != null && _signedInRoutes.contains(lastRoute)) {
    return lastRoute;
  }

  return _signedInFallbackRoute;
}

class AppRouteObserver extends NavigatorObserver {
  AppRouteObserver(this._prefs);

  final SharedPreferences _prefs;

  void _saveRoute(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null || name.isEmpty) return;
    // Fire-and-forget; observer methods must stay synchronous.
    unawaited(_prefs.setString('last_route', name));
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _saveRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _saveRoute(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Persist the route you land on after pop.
    _saveRoute(previousRoute);
  }
}

class PresMAIApp extends StatelessWidget {
  const PresMAIApp({
    super.key,
    required this.initialRoute,
    required this.prefs,
  });

  final String initialRoute;
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PresMAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute,
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/chat': (context) => const AiChatScreen(),
        '/alerts': (context) => const AlertsScreen(),
        '/archive': (context) => const ArchiveScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
      navigatorObservers: <NavigatorObserver>[
        AppRouteObserver(prefs),
      ],
    );
  }
}
