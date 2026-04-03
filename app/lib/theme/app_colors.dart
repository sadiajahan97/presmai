import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF13C8EC);
  static const Color primaryLight = Color(0x3313C8EC); // primary/20
  static const Color primarySubtle = Color(0x0D13C8EC); // primary/5
  static const Color primaryBorder = Color(0x1A13C8EC); // primary/10
  static const Color primaryShadow = Color(0x3313C8EC); // primary/20

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF6F8F8);
  static const Color backgroundDark = Color(0xFF101F22);

  // Slate palette (Tailwind equivalents)
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // Functional
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color error = Color(0xFFEF4444); // Red-500
}
