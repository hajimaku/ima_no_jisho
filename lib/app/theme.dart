import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0A0A14); // 墨
  static const Color card = Color(0xFF12121F);        // カード背景
  static const Color washi = Color(0xFFF5F0E8);       // メインテキスト（和紙）
  static const Color vermillion = Color(0xFFE84A2F);  // アクセント（朱）＝今の意味
  static const Color gold = Color(0xFFC9A84C);        // 今日の一言
  static const Color indigo = Color(0xFF3D5A8A);      // 辞書的意味

  static const Color dictBlock = Color(0xFF0D1520);   // 辞書的意味ブロック背景
  static const Color modernBlock = Color(0xFF1A0A08); // 今の意味ブロック背景
}

class AppTheme {
  static const String _serif = 'Noto Serif JP';
  static const String _sans  = 'Noto Sans JP';

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.card,
      colorScheme: const ColorScheme.dark(
        background: AppColors.background,
        surface: AppColors.card,
        primary: AppColors.vermillion,
        secondary: AppColors.gold,
        tertiary: AppColors.indigo,
        onBackground: AppColors.washi,
        onSurface: AppColors.washi,
        onPrimary: AppColors.washi,
      ),
      textTheme: const TextTheme(
        // 見出し：Noto Serif JP
        displayLarge: TextStyle(
          fontFamily: _serif,
          color: AppColors.washi,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: TextStyle(
          fontFamily: _serif,
          color: AppColors.washi,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: TextStyle(
          fontFamily: _serif,
          color: AppColors.washi,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          fontFamily: _serif,
          color: AppColors.washi,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        // 本文：Noto Sans JP
        bodyLarge: TextStyle(
          fontFamily: _sans,
          color: AppColors.washi,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          fontFamily: _sans,
          color: AppColors.washi,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          fontFamily: _sans,
          color: AppColors.washi,
          fontSize: 12,
        ),
        labelLarge: TextStyle(
          fontFamily: _sans,
          color: AppColors.washi,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: _serif,
          color: AppColors.washi,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: AppColors.washi),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(
          fontFamily: _sans,
          color: Color(0x66F5F0E8),
          fontSize: 16,
        ),
      ),
    );
  }
}
