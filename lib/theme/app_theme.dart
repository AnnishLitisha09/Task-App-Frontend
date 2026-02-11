import 'package:flutter/material.dart';

class AppTheme {
  // --- Modern Design Tokens ---
  static const Color brandPrimary = Color(0xFF0F172A);
  static const Color brandAccent = Color(0xFF6366F1);
  static const Color surfaceColor = Color(0xFFF8FAFC);
  static const Color textMain = Color(0xFF1E293B);
  static const Color textSub = Color(0xFF64748B);
  static const Color dividerColor = Color(0xFFF1F5F9);
  
  // --- Status Colors ---
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFF43F5E);
  static const Color info = Color(0xFF3B82F6);

  // --- Common Decorations ---
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: brandPrimary.withOpacity(0.04),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static BoxDecoration bentoDecoration(Color col) => BoxDecoration(
    color: col.withOpacity(0.08),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: col.withOpacity(0.1)),
  );

  // --- Text Styles ---
  static const TextStyle h1 = TextStyle(
    color: textMain,
    fontSize: 24,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    color: textMain,
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle bodyMain = TextStyle(
    color: textMain,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle bodySub = TextStyle(
    color: textSub,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle caption = TextStyle(
    color: textSub,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle overline = TextStyle(
    color: textSub,
    fontSize: 11,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.2,
  );
}
