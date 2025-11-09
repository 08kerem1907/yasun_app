import 'package:flutter/material.dart';
import 'colors.dart'; // AppColors'a erişim için

class AppTheme {
  static const Color primary1 = Color(0xFF7C4DFF);
  static const Color primary2 = Color(0xFF6A5AE0);

  static ThemeData get darkRelaxedTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Arka plan ve yüzey tonları: saf siyah değil, koyu gri-mor
      scaffoldBackgroundColor: const Color(0xFF1E1B26),
      colorScheme: ColorScheme.dark(
        primary: primary2,
        secondary: primary1,
        surface: const Color(0xFF262331),
        background: const Color(0xFF1E1B26),
      ),

      // Text alanları ve kartlar
      cardColor: const Color(0xFF2B2835),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2E2B39),
        labelStyle: const TextStyle(color: Color(0xFFBFBFD5)),
        hintStyle: const TextStyle(color: Color(0xFF88889C)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3F3B4F)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary2, width: 1.5),
        ),
      ),

      // Yazılar: beyaz değil, gri tonlu rahat kontrast
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Color(0xFFEDEBFF),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFFBEBED4),
        ),
      ),

      // Butonlar
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          // Gradient'i Color'a dönüştürme hatasını önlemek için
          backgroundColor: primary2, 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),

      iconTheme: const IconThemeData(color: Color(0xFFBFBFD5)),
    );
  }
}
