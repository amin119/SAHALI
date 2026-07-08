import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Brightness-aware accessor over [AppColors]/[AppColorsDark] so screens
/// don't need to write `isDark ? AppColorsDark.x : AppColors.x` per color.
/// Usage: `final p = AppPalette.of(context); ...color: p.textPrimary`
class AppPalette {
  const AppPalette(this.isDark);

  factory AppPalette.of(BuildContext context) =>
      AppPalette(Theme.of(context).brightness == Brightness.dark);

  final bool isDark;

  // ── v2 design system ────────────────────────────────────────────────────
  Color get gradientOrange => isDark ? AppColorsDark.gradientOrange : AppColors.gradientOrange;
  Color get gradientYellow => isDark ? AppColorsDark.gradientYellow : AppColors.gradientYellow;
  Color get gradientGreen => isDark ? AppColorsDark.gradientGreen : AppColors.gradientGreen;
  Color get gradientBlue => isDark ? AppColorsDark.gradientBlue : AppColors.gradientBlue;
  List<Color> get livingGradientColors => [gradientOrange, gradientYellow, gradientGreen, gradientBlue, gradientOrange];

  Color get ink => isDark ? AppColorsDark.ink : AppColors.ink;
  Color get inkSoft => isDark ? AppColorsDark.inkSoft : AppColors.inkSoft;

  Color get urgent => isDark ? AppColorsDark.urgent : AppColors.urgent;
  Color get urgentSoft => isDark ? AppColorsDark.urgentSoft : AppColors.urgentSoft;
  Color get safe => isDark ? AppColorsDark.safe : AppColors.safe;
  Color get safeSoft => isDark ? AppColorsDark.safeSoft : AppColors.safeSoft;

  Color get primary => isDark ? AppColorsDark.primary : AppColors.primary;
  Color get primaryLight => isDark ? AppColorsDark.primaryLight : AppColors.primaryLight;
  Color get primaryContainer => isDark ? AppColorsDark.primaryContainer : AppColors.primaryContainer;

  Color get accentStart => isDark ? AppColorsDark.accentStart : AppColors.accentStart;
  Color get accentEnd => isDark ? AppColorsDark.accentEnd : AppColors.accentEnd;
  Gradient get accentGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accentStart, accentEnd],
      );

  Color get background => isDark ? AppColorsDark.background : AppColors.background;
  Color get surface => isDark ? AppColorsDark.surface : AppColors.surface;
  Color get surfaceVariant => isDark ? AppColorsDark.surfaceVariant : AppColors.surfaceVariant;
  Color get surfaceContainer => isDark ? AppColorsDark.surfaceContainer : AppColors.surfaceContainer;

  Color get textPrimary => isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
  Color get textSecondary => isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
  Color get textHint => isDark ? AppColorsDark.textHint : AppColors.textHint;

  Color get border => isDark ? AppColorsDark.border : AppColors.border;
  Color get divider => isDark ? AppColorsDark.divider : AppColors.divider;

  Color get success => isDark ? AppColorsDark.success : AppColors.success;
  Color get successContainer => isDark ? AppColorsDark.successContainer : AppColors.successContainer;
  Color get warning => isDark ? AppColorsDark.warning : AppColors.warning;
  Color get warningContainer => isDark ? AppColorsDark.warningContainer : AppColors.warningContainer;
  Color get error => isDark ? AppColorsDark.error : AppColors.error;
  Color get errorContainer => isDark ? AppColorsDark.errorContainer : AppColors.errorContainer;
  Color get info => isDark ? AppColorsDark.info : AppColors.info;
  Color get infoSoft => isDark ? AppColorsDark.infoSoft : AppColors.infoSoft;

  Color get statusSubmitted => isDark ? AppColorsDark.statusSubmitted : AppColors.statusSubmitted;
  Color get statusReceived => isDark ? AppColorsDark.statusReceived : AppColors.statusReceived;
  Color get statusUnderReview => isDark ? AppColorsDark.statusUnderReview : AppColors.statusUnderReview;
  Color get statusInProgress => isDark ? AppColorsDark.statusInProgress : AppColors.statusInProgress;
  Color get statusResolved => isDark ? AppColorsDark.statusResolved : AppColors.statusResolved;
  Color get statusClosed => isDark ? AppColorsDark.statusClosed : AppColors.statusClosed;
  Color get statusRejected => isDark ? AppColorsDark.statusRejected : AppColors.statusRejected;

  Color get catInfrastructure => isDark ? AppColorsDark.catInfrastructure : AppColors.catInfrastructure;
  Color get catLighting => isDark ? AppColorsDark.catLighting : AppColors.catLighting;
  Color get catWaste => isDark ? AppColorsDark.catWaste : AppColors.catWaste;
  Color get catEnvironment => isDark ? AppColorsDark.catEnvironment : AppColors.catEnvironment;
  Color get catWater => isDark ? AppColorsDark.catWater : AppColors.catWater;
  Color get catTransport => isDark ? AppColorsDark.catTransport : AppColors.catTransport;
  Color get catSafety => isDark ? AppColorsDark.catSafety : AppColors.catSafety;
}
