import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Royal Lavender Palette - Light
  static const Color primaryColor = Color(0xFF673AB7); // Deep Purple 500
  static const Color primaryDark = Color(0xFF512DA8); // Deep Purple 700
  static const Color mixedColor = Color(0xFF9575CD); // Deep Purple 300
  static const Color scaffoldLight = Color(0xFFF3E5F5); // Purple 50 (lighter)
  static const Color cardLight = Color(0xFFFFFFFF);
  
  // Royal Lavender Palette - Dark
  static const Color scaffoldDark = Color(0xFF121212); // Near Black
  static const Color cardDark = Color(0xFF1E1E1E); // Dark Grey
  static const Color surfaceDark = Color(0xFF2C2C2C); // Slightly lighter grey

  static TextTheme _buildTextTheme(TextTheme base, Color color) {
    return GoogleFonts.interTextTheme(base).apply(
      bodyColor: color,
      displayColor: color,
    );
  }

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: scaffoldLight,
    cardColor: cardLight,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: mixedColor,
      surface: cardLight,
      error: Color(0xFFD32F2F),
      onPrimary: Colors.white,
    ),
    textTheme: _buildTextTheme(ThemeData.light().textTheme, const Color(0xFF1D1B20)),
    
    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      hintStyle: TextStyle(color: Colors.grey.shade400),
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        elevation: 4,
        shadowColor: primaryColor.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: mixedColor, // Lighter purple for dark mode
    scaffoldBackgroundColor: scaffoldDark,
    cardColor: cardDark,
    colorScheme: const ColorScheme.dark(
      primary: mixedColor,
      secondary: primaryColor,
      surface: cardDark,
      error: Color(0xFFCF6679),
      onPrimary: Colors.black,
    ),
    textTheme: _buildTextTheme(ThemeData.dark().textTheme, const Color(0xFFE6E1E5)),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: mixedColor, width: 2),
      ),
      hintStyle: TextStyle(color: Colors.grey.shade600),
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black, // Dark mode buttons text color
        backgroundColor: mixedColor,
        elevation: 4,
        shadowColor: mixedColor.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
