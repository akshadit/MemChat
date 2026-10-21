import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand & Chat Colors
  static const Color primaryEmerald = Color(0xFF10B981);
  static const Color whatsappGreen = Color(0xFF25D366);
  static const Color darkCanvas = Color(0xFF0C0F17);
  static const Color darkSurface = Color(0xFF151A24);
  static const Color cardElevated = Color(0xFF1C2230);
  static const Color cardBorder = Color(0xFF293245);
  
  // Chat Bubble Colors
  static const Color outgoingBubble = Color(0xFF064E3B); // Deep emerald
  static const Color outgoingBorder = Color(0xFF047857);
  static const Color incomingBubble = Color(0xFF1A212E);
  static const Color incomingBorder = Color(0xFF2C364B);

  // Text Colors
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkCanvas,
      primaryColor: primaryEmerald,
      cardColor: darkSurface,
      colorScheme: const ColorScheme.dark(
        primary: primaryEmerald,
        surface: darkSurface,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        titleLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.4,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.4,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
      ),
    );
  }
}
