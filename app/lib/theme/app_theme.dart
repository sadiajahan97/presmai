import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.manropeTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        surface: AppColors.backgroundLight,
        onPrimary: AppColors.slate900,
        onSurface: AppColors.slate900,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: AppColors.slate900,
        displayColor: AppColors.slate900,
      ),
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.slate900,
        selectionColor: AppColors.slate200,
        selectionHandleColor: AppColors.slate900,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.slate900),
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.slate900,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: GoogleFonts.manrope(
          color: AppColors.slate400,
          fontSize: 14,
        ),
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.slate900,
          overlayColor: Colors.transparent,
          elevation: 4,
          shadowColor: AppColors.primaryShadow,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ).copyWith(
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.basic),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          overlayColor: Colors.transparent,
        ).copyWith(
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.basic),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          overlayColor: Colors.transparent,
        ).copyWith(
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.basic),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ).copyWith(
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.basic),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.basic),
      ),
      menuBarTheme: MenuBarThemeData(
        style: MenuStyle(
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.basic),
        ),
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: MenuItemButton.styleFrom(
          overlayColor: Colors.transparent,
        ).copyWith(
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.basic),
        ),
      ),
    );
  }
}
