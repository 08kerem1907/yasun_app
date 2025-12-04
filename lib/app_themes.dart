import 'package:flutter/material.dart';

ThemeData buildLightTheme() {
  final base = ThemeData.light();
  return base.copyWith(
    useMaterial3: true,
    colorScheme: base.colorScheme.copyWith(
      primary: const Color(0xFF1565C0), // marka primary (örnek)
      secondary: const Color(0xFF00ACC1),
      background: const Color(0xFFF5F7FA),
      surface: Colors.white,
      onPrimary: Colors.white,
      onBackground: Colors.black,
      onSurface: Colors.black87,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
      bodySmall: TextStyle(fontSize: 12, color: Colors.black54),
    ),
    iconTheme: const IconThemeData(color: Colors.black87),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
    ),
  );
}

ThemeData buildDarkTheme() {
  final base = ThemeData.dark();
  return base.copyWith(
    useMaterial3: true,
    colorScheme: base.colorScheme.copyWith(
      primary: const Color(0xFF90CAF9),
      secondary: const Color(0xFF80DEEA),
      background: const Color(0xFF0F1720),
      surface: const Color(0xFF121318),
      onPrimary: Colors.black,
      onBackground: Colors.white,
      onSurface: Colors.white70,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F1720),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121318),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF1E1E1E),  // Dark tema için uygun koyu renk
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
      bodySmall: TextStyle(fontSize: 12, color: Colors.white60),
    ),
    iconTheme: const IconThemeData(color: Colors.white70),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF90CAF9),
        foregroundColor: Colors.black,
      ),
    ),
  );
}
