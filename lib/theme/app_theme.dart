import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // WhatsApp Dark Mode Core Colors
  static const Color darkCanvas = Color(0xFF0B141A);       // WhatsApp deep dark wallpaper base
  static const Color darkAppBar = Color(0xFF1F2C34);       // Authentic WhatsApp top bar
  static const Color darkSurface = Color(0xFF111B21);      // List tiles and card surface
  static const Color cardElevated = Color(0xFF202C33);     // Elevated elements & chips
  static const Color cardBorder = Color(0xFF222D34);       // Subtle divider line
  static const Color inputPill = Color(0xFF2A3942);        // WhatsApp input pill background

  // Brand Accents
  static const Color whatsappTeal = Color(0xFF00A884);     // WhatsApp primary CTA & floating button
  static const Color whatsappGreen = Color(0xFF25D366);    // Vibrant status green
  static const Color whatsappCheckBlue = Color(0xFF53BDEB);// WhatsApp read receipt double blue check

  // Chat Bubble Colors (Authentic WhatsApp Dark Mode)
  static const Color outgoingBubble = Color(0xFF005C4B);   // Deep emerald outgoing bubble
  static const Color outgoingBorder = Color(0xFF025143);
  static const Color incomingBubble = Color(0xFF202C33);   // Dark slate incoming bubble
  static const Color incomingBorder = Color(0xFF2A3942);
  static const Color dateChipBackground = Color(0xFF182229);

  // Text Colors
  static const Color textPrimary = Color(0xFFE9EDEF);      // WhatsApp primary high-contrast text
  static const Color textSecondary = Color(0xFF8696A0);    // WhatsApp secondary subtitle text
  static const Color textMuted = Color(0xFF667781);        // WhatsApp timestamps and captions

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkCanvas,
      primaryColor: whatsappTeal,
      cardColor: darkSurface,
      canvasColor: darkCanvas,
      dialogBackgroundColor: darkAppBar,
      colorScheme: const ColorScheme.dark(
        primary: whatsappTeal,
        surface: darkSurface,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.35,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.35,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkAppBar,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textSecondary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
