import 'package:flutter/material.dart';

class AppColors {
  // /Ana renkler
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  
  // Arka plan renkleri
  static const Color background = Color(0xFFF5F7FF);
  static const Color cardBackground = Colors.white;
  
  // Metin renkleri
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  
  // Border renkleri
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderFocused = Color(0xFF6366F1);
  
  // Durum renkleri
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  
  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
