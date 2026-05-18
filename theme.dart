import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors
  static const Color green        = Color(0xFF00E5A0); // vibrant teal-green
  static const Color greenDark    = Color(0xFF00B37E);
  static const Color pink         = Color(0xFFFF4D8B);
  static const Color blue         = Color(0xFF4D9FFF);
  static const Color purple       = Color(0xFF9B6DFF);
  static const Color amber        = Color(0xFFFFB547);

  // Light mode
  static const Color bgLight      = Color(0xFFF2F3F8);
  static const Color cardLight    = Color(0xFFFFFFFF);
  static const Color textPrimary  = Color(0xFF0D0D0D);
  static const Color textSecondary= Color(0xFF8A8A9A);

  // Dark mode
  static const Color bgDark       = Color(0xFF080B14);
  static const Color cardDark     = Color(0xFF111827);
  static const Color cardDark2    = Color(0xFF1A2235);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: green, brightness: Brightness.light),
    scaffoldBackgroundColor: bgLight,
    cardColor: cardLight,
    textTheme: GoogleFonts.dmSansTextTheme(),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cardLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: green, brightness: Brightness.dark),
    scaffoldBackgroundColor: bgDark,
    cardColor: cardDark,
    textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  static ThemeData get theme => lightTheme;
}

// Context-aware colors
class AC {
  static bool isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  static Color bg(BuildContext c) =>
      isDark(c) ? AppTheme.bgDark : AppTheme.bgLight;

  static Color card(BuildContext c) =>
      isDark(c) ? AppTheme.cardDark : AppTheme.cardLight;

  static Color card2(BuildContext c) =>
      isDark(c) ? AppTheme.cardDark2 : const Color(0xFFF8F8FF);

  static Color cardGreen(BuildContext c) =>
      isDark(c) ? const Color(0xFF0A2018) : const Color(0xFFE6FDF5);

  static Color cardPurple(BuildContext c) =>
      isDark(c) ? const Color(0xFF1A1030) : const Color(0xFFF0EBFF);

  static Color cardBlue(BuildContext c) =>
      isDark(c) ? const Color(0xFF0A1828) : const Color(0xFFEBF4FF);

  static Color cardPink(BuildContext c) =>
      isDark(c) ? const Color(0xFF280A18) : const Color(0xFFFFEBF3);

  static Color text(BuildContext c) =>
      isDark(c) ? Colors.white : AppTheme.textPrimary;

  static Color subtext(BuildContext c) =>
      isDark(c) ? const Color(0xFF8A8A9A) : AppTheme.textSecondary;

  static Color divider(BuildContext c) =>
      isDark(c) ? const Color(0xFF1E2A3A) : const Color(0xFFEEEEF5);
}