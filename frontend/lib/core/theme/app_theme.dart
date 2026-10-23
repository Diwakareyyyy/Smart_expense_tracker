import 'package:flutter/material.dart';

class AppTheme {
  /// ---------- LIGHT THEME ----------
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    primaryColor: const Color(0xFF7B4DFF),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE2E8F0),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF8FAFC),
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF0F172A)),
    ),

    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7B4DFF),
      brightness: Brightness.light,
      surface: Colors.white,
      onSurface: const Color(0xFF0F172A),
      primary: const Color(0xFF7B4DFF),
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: Color(0xFF334155), fontSize: 14),
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF0F172A), fontSize: 16),
      bodyMedium: TextStyle(color: Color(0xFF334155), fontSize: 14),
      titleLarge: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 20),
      titleMedium: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 16),
      labelLarge: TextStyle(color: Color(0xFF64748B), fontSize: 14),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF7B4DFF),
      foregroundColor: Colors.white,
      elevation: 4,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7B4DFF),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF1F5F9),
      disabledColor: const Color(0xFFE2E8F0),
      selectedColor: const Color(0xFF7B4DFF),
      secondarySelectedColor: const Color(0xFF7B4DFF),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      labelStyle: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
      secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      brightness: Brightness.light,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF7B4DFF),
      unselectedItemColor: Color(0xFF94A3B8),
      elevation: 8,
    ),
  );

  /// ---------- DARK THEME ----------
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF070B16),
    primaryColor: const Color(0xFF7B4DFF),
    cardColor: const Color(0xFF1B233A),
    dividerColor: const Color(0xFF2A3045),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF070B16),
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),

    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7B4DFF),
      brightness: Brightness.dark,
      surface: const Color(0xFF1B233A),
      onSurface: Colors.white,
      primary: const Color(0xFF7B4DFF),
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF1B233A),
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: Colors.white70, fontSize: 14),
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
      titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
      labelLarge: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF7B4DFF),
      foregroundColor: Colors.white,
      elevation: 4,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7B4DFF),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF262E4A),
      disabledColor: const Color(0xFF1B233A),
      selectedColor: const Color(0xFF7B4DFF),
      secondarySelectedColor: const Color(0xFF7B4DFF),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
      secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      brightness: Brightness.dark,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF161B2F),
      selectedItemColor: Color(0xFF9D74FF),
      unselectedItemColor: Color(0xFF9CA3AF),
      elevation: 0,
    ),
  );
}