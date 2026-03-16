// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────
///  DESIGN TOKENS — Phòng Trọ 4.0 Flat Design
/// ─────────────────────────────────────────────
class AppColors {
  // Base
  static const background   = Color(0xFFFFFFFF);
  static const foreground   = Color(0xFF111827); // Gray 900
  static const muted        = Color(0xFFF3F4F6); // Gray 100
  static const surface      = Color(0xFFF9FAFB); // Gray 50
  static const border       = Color(0xFFE5E7EB); // Gray 200
  static const textSecondary = Color(0xFF6B7280); // Gray 500
  static const textMuted    = Color(0xFF9CA3AF); // Gray 400

  // Semantic / Action
  static const primary      = Color(0xFF3B82F6); // Blue 500
  static const primaryDark  = Color(0xFF2563EB); // Blue 600
  static const success      = Color(0xFF10B981); // Emerald 500
  static const successLight = Color(0xFFD1FAE5); // Emerald 100
  static const successDark  = Color(0xFF065F46); // Emerald 800
  static const warning      = Color(0xFFF59E0B); // Amber 500
  static const warningLight = Color(0xFFFEF3C7); // Amber 100
  static const warningDark  = Color(0xFF92400E); // Amber 800
  static const danger       = Color(0xFFEF4444); // Red 500
  static const dangerLight  = Color(0xFFFEE2E2); // Red 100
  static const dangerDark   = Color(0xFF991B1B); // Red 800

  // Sidebar
  static const sidebarBg    = Color(0xFF111827); // Gray 900
  static const sidebarBorder = Color(0xFF1F2937); // Gray 800
  static const sidebarText  = Color(0xFF9CA3AF); // Gray 400
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      surface: AppColors.background,
      error: AppColors.danger,
    ),
    textTheme: GoogleFonts.outfitTextTheme().copyWith(
      displayLarge: GoogleFonts.outfit(
        fontSize: 32, fontWeight: FontWeight.w800,
        color: AppColors.foreground, letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 24, fontWeight: FontWeight.w800,
        color: AppColors.foreground, letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 18, fontWeight: FontWeight.w800,
        color: AppColors.foreground,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 16, fontWeight: FontWeight.w700,
        color: AppColors.foreground,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 14, fontWeight: FontWeight.w500,
        color: AppColors.foreground,
      ),
      bodyMedium: GoogleFonts.outfit(
        fontSize: 13, fontWeight: FontWeight.w400,
        color: AppColors.foreground,
      ),
      labelSmall: GoogleFonts.outfit(
        fontSize: 10, fontWeight: FontWeight.w700,
        color: AppColors.textSecondary, letterSpacing: 1.0,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border, thickness: 2, space: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.muted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
  );
}
