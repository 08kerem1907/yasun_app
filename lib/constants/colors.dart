import 'package:flutter/material.dart';

class AppColors {
  // ========== LIGHT MODE ==========

  // Ana renkler
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

  // ========== DARK MODE ==========

  // Dark mode ana renkler
  static const Color darkPrimary = Color(0xFF818CF8); // Lighter Indigo
  static const Color darkPrimaryDark = Color(0xFF6366F1);
  static const Color darkPrimaryLight = Color(0xFFA5B4FC);

  // Dark mode arka plan renkleri
  static const Color darkBackground = Color(0xFF0F1420);
  static const Color darkCardBackground = Color(0xFF1A202C);
  static const Color darkCardBackgroundSecondary = Color(0xFF2D3748);

  // Dark mode metin renkleri
  static const Color darkTextPrimary = Color(0xFFF7F8F9);
  static const Color darkTextSecondary = Color(0xFFBCC3CF);
  static const Color darkTextHint = Color(0xFF8894A1);

  // Dark mode border renkleri
  static const Color darkBorder = Color(0xFF2D3748);
  static const Color darkBorderFocused = Color(0xFF818CF8);

  // Dark mode durum renkleri
  static const Color darkSuccess = Color(0xFF34D399);
  static const Color darkError = Color(0xFFF87171);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkInfo = Color(0xFF60A5FA);

  // Dark mode Gradient
  static const LinearGradient darkPrimaryGradient = LinearGradient(
    colors: [Color(0xFF818CF8), Color(0xFFA78BFA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    colors: [Color(0xFF0F1420), Color(0xFF1A202C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ========== HELPER METHODS ==========

  /// Tema türüne göre uygun rengi döndür
  static Color getColor(
      BuildContext context, {
        required Color light,
        required Color dark,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? dark : light;
  }

  /// Tema türüne göre gradient döndür
  static LinearGradient getGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkBackgroundGradient : backgroundGradient;
  }

  /// Tema türüne göre ana gradient döndür
  static LinearGradient getPrimaryGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkPrimaryGradient : primaryGradient;
  }

  /// Tema türüne göre kart arka plan rengini döndür
  static Color getCardBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkCardBackground : cardBackground;
  }

  /// Tema türüne göre metin rengini döndür
  static Color getTextColor(
      BuildContext context, {
        bool primary = true,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return primary ? darkTextPrimary : darkTextSecondary;
    }
    return primary ? textPrimary : textSecondary;
  }

  /// Tema türüne göre başarı rengini döndür
  static Color getSuccessColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkSuccess : success;
  }

  /// Tema türüne göre hata rengini döndür
  static Color getErrorColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkError : error;
  }

  /// Tema türüne göre uyarı rengini döndür
  static Color getWarningColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkWarning : warning;
  }

  /// Tema türüne göre bilgi rengini döndür
  static Color getInfoColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkInfo : info;
  }

  /// Tema türüne göre birincil rengi döndür
  static Color getPrimaryColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkPrimary : primary;
  }
}
