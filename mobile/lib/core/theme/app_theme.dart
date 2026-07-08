import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_shapes.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.primary,
        secondary: AppColors.textSecondary,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.surfaceVariant,
        onSecondaryContainer: AppColors.textPrimary,
        tertiary: AppColors.catSafety,
        onTertiary: Colors.white,
        tertiaryContainer: AppColors.errorContainer,
        onTertiaryContainer: AppColors.error,
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.error,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
        outlineVariant: AppColors.divider,
        surfaceContainerHighest: AppColors.surfaceVariant,
        surfaceContainerHigh: AppColors.surfaceContainer,
        surfaceContainer: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _buildTextTheme(),
      appBarTheme: _appBarTheme(),
      elevatedButtonTheme: _elevatedButtonTheme(primary: AppColors.ink),
      outlinedButtonTheme: _outlinedButtonTheme(),
      textButtonTheme: _textButtonTheme(),
      inputDecorationTheme: _inputDecorationTheme(),
      cardTheme: _cardTheme(),
      bottomNavigationBarTheme: _bottomNavTheme(),
      chipTheme: _chipTheme(),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColorsDark.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColorsDark.primaryContainer,
        onPrimaryContainer: AppColorsDark.primary,
        secondary: AppColorsDark.textSecondary,
        onSecondary: Colors.white,
        secondaryContainer: AppColorsDark.surfaceVariant,
        onSecondaryContainer: AppColorsDark.textPrimary,
        tertiary: AppColorsDark.catSafety,
        onTertiary: Colors.white,
        tertiaryContainer: AppColorsDark.errorContainer,
        onTertiaryContainer: AppColorsDark.error,
        error: AppColorsDark.error,
        onError: Colors.white,
        errorContainer: AppColorsDark.errorContainer,
        onErrorContainer: AppColorsDark.error,
        surface: AppColorsDark.surface,
        onSurface: AppColorsDark.textPrimary,
        onSurfaceVariant: AppColorsDark.textSecondary,
        outline: AppColorsDark.border,
        outlineVariant: AppColorsDark.divider,
        surfaceContainerHighest: AppColorsDark.surfaceVariant,
        surfaceContainerHigh: AppColorsDark.surfaceContainer,
        surfaceContainer: AppColorsDark.background,
      ),
      scaffoldBackgroundColor: AppColorsDark.background,
      textTheme: _buildTextTheme(color: AppColorsDark.textPrimary, secondaryColor: AppColorsDark.textSecondary, hintColor: AppColorsDark.textHint),
      appBarTheme: _appBarTheme(surface: AppColorsDark.surface, text: AppColorsDark.textPrimary, border: AppColorsDark.border, iconBrightness: Brightness.light),
      elevatedButtonTheme: _elevatedButtonTheme(primary: AppColorsDark.ink, onPrimary: AppColorsDark.background),
      outlinedButtonTheme: _outlinedButtonTheme(primary: AppColorsDark.ink, border: AppColorsDark.border),
      textButtonTheme: _textButtonTheme(primary: AppColorsDark.ink),
      inputDecorationTheme: _inputDecorationTheme(
        surface: AppColorsDark.surface, border: AppColorsDark.border, primary: AppColorsDark.ink,
        error: AppColorsDark.error, hint: AppColorsDark.textHint, secondary: AppColorsDark.textSecondary,
      ),
      cardTheme: _cardTheme(surface: AppColorsDark.surface, divider: AppColorsDark.divider),
      bottomNavigationBarTheme: _bottomNavTheme(surface: AppColorsDark.surface, primary: AppColorsDark.primary, hint: AppColorsDark.textHint),
      chipTheme: _chipTheme(surfaceVariant: AppColorsDark.surfaceVariant),
      dividerTheme: const DividerThemeData(
        color: AppColorsDark.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static TextTheme _buildTextTheme({
    Color color = AppColors.textPrimary,
    Color secondaryColor = AppColors.textSecondary,
    Color hintColor = AppColors.textHint,
  }) {
    return TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 34, fontWeight: FontWeight.w800, color: color,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 28, fontWeight: FontWeight.w800, color: color,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 24, fontWeight: FontWeight.w700, color: color,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 22, fontWeight: FontWeight.w700, color: color,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20, fontWeight: FontWeight.w700, color: color,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w700, color: color,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w700, color: color,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w600, color: color,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w600, color: color,
        letterSpacing: 0.02,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w400, color: color,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w400, color: color,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w400, color: secondaryColor,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w600, color: color,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w600, color: secondaryColor,
        letterSpacing: 0.02,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 11, fontWeight: FontWeight.w500, color: hintColor,
        letterSpacing: 0.02,
      ),
    );
  }

  static AppBarTheme _appBarTheme({
    Color surface = AppColors.surface,
    Color text = AppColors.textPrimary,
    Color border = AppColors.border,
    Brightness iconBrightness = Brightness.dark,
  }) {
    return AppBarTheme(
      backgroundColor: surface,
      foregroundColor: text,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: border.withValues(alpha: 0.5),
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
      ),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: text,
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme({
    Color primary = AppColors.ink,
    Color onPrimary = Colors.white,
  }) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        minimumSize: const Size(double.infinity, 54),
        shape: AppShapes.pill(),
        elevation: 0,
        textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme({
    Color primary = AppColors.ink,
    Color border = AppColors.border,
  }) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size(double.infinity, 54),
        shape: AppShapes.pill(),
        side: BorderSide(color: border),
        textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme({Color primary = AppColors.ink}) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme({
    Color surface = AppColors.surface,
    Color border = AppColors.border,
    Color primary = AppColors.primary,
    Color error = AppColors.error,
    Color hint = AppColors.textHint,
    Color secondary = AppColors.textSecondary,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: AppShapes.radius(AppShapes.radiusMd),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppShapes.radius(AppShapes.radiusMd),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppShapes.radius(AppShapes.radiusMd),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppShapes.radius(AppShapes.radiusMd),
        borderSide: BorderSide(color: error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppShapes.radius(AppShapes.radiusMd),
        borderSide: BorderSide(color: error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.poppins(
        fontSize: 14, color: hint, fontWeight: FontWeight.w400,
      ),
      labelStyle: GoogleFonts.poppins(
        fontSize: 14, color: secondary,
      ),
    );
  }

  static CardThemeData _cardTheme({
    Color surface = AppColors.surface,
    Color divider = AppColors.divider,
  }) {
    return CardThemeData(
      color: surface,
      elevation: 0,
      shape: AppShapes.border(radius: AppShapes.radiusLg, borderColor: divider),
      margin: EdgeInsets.zero,
    );
  }

  static BottomNavigationBarThemeData _bottomNavTheme({
    Color surface = AppColors.surface,
    Color primary = AppColors.primary,
    Color hint = AppColors.textHint,
  }) {
    return BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: hint,
      selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    );
  }

  static ChipThemeData _chipTheme({Color surfaceVariant = AppColors.surfaceVariant}) {
    return ChipThemeData(
      backgroundColor: surfaceVariant,
      labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
      shape: AppShapes.pill(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      side: BorderSide.none,
    );
  }
}
