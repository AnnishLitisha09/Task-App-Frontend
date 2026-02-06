import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Royal Lavender Palette
  static const Color primaryColor = Color(0xFF5E35B1); // Deep Purple 600
  static const Color scaffoldBackgroundColor = Color(0xFFEDE7F6); // Deep Purple 50
  static const Color cardColor = Color(0xFFF3E5F5); // Purple 50 (slightly different tone for card) (Actually let's make it lighter than BG for lift, or slightly darker? User said "mild color of background". Usually means same hue, different lightness.
  // Let's try:
  // BG: #EDE7F6 (Deep Purple 50)
  // Card: #FFFFFF (White) tinted with Purple, or just #F5F5F5. 
  // User said "mild color of background". Let's use a very light tint.
  static const Color secondaryColor = Color(0xFF673AB7); // Deep Purple

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: scaffoldBackgroundColor, 
    cardColor: const Color(0xFFF8F5FB), // Very light lavender, almost white but matches BG tone
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: const Color(0xFF4527A0), // Dark Purple for text
      displayColor: const Color(0xFF4527A0),
    ),
    
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
        borderSide: BorderSide.none, // Clean look
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
}
