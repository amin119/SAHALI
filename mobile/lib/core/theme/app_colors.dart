import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Design system v2 ──────────────────────────────────────────────────────
  // The app's identity is the living pastel gradient behind every screen, not
  // a brand color. Accent colors (urgent/info/safe) are reserved for meaning
  // only; regular buttons/CTAs use `ink`, a warm near-black.

  // Living gradient stops (see SaAnimatedBackground)
  static const gradientOrange = Color(0xFFFFB894);
  static const gradientYellow = Color(0xFFFFE29A);
  static const gradientGreen = Color(0xFFB9EAC5);
  static const gradientBlue = Color(0xFFA8D8EF);

  // Ink — solid CTAs and primary text on floating white cards
  static const ink = Color(0xFF262722);
  static const inkSoft = Color(0xFF52533F);

  // Semantic accents — meaning only, never decorative
  static const urgent = Color(0xFFFF6B4A);
  static const urgentSoft = Color(0xFFFFE4DC);
  static const info = Color(0xFF4C8DFF);
  static const infoSoft = Color(0xFFE3ECFF);
  static const safe = Color(0xFF34C77B);
  static const safeSoft = Color(0xFFDEF7E7);

  // Brand (legacy — kept only for any not-yet-migrated reference)
  static const primary = Color(0xFF0038AF);
  static const primaryLight = Color(0xFF1B4FD8);
  static const primaryContainer = Color(0xFFDCE1FF);

  // Accent — "Meadow" gradient, superseded by the v2 system above.
  static const accentStart = Color(0xFF00BFA6);
  static const accentEnd = Color(0xFFB0E63C);

  // Background / Surface
  static const background = Color(0xFFF5F6FF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFE8E7F3);
  static const surfaceContainer = Color(0xFFEDEDF8);

  // Text
  static const textPrimary = Color(0xFF191B23);
  static const textSecondary = Color(0xFF434655);
  static const textHint = Color(0xFF747686);

  // Border
  static const border = Color(0xFFC4C5D7);
  static const divider = Color(0xFFE2E1ED);

  // Status (legacy — superseded by urgent/info/safe above; warning kept for
  // non-semantic "heads up" notices like dev-only hints)
  static const success = Color(0xFF00875A);
  static const successContainer = Color(0xFFE3FCEF);
  static const warning = Color(0xFFFF8B00);
  static const warningContainer = Color(0xFFFFF4E5);
  static const error = Color(0xFFDE350B);
  static const errorContainer = Color(0xFFFFEDEB);

  // Report status colors
  static const statusSubmitted = Color(0xFF747686);
  static const statusReceived = Color(0xFF0065FF);
  static const statusUnderReview = Color(0xFFFF8B00);
  static const statusInProgress = Color(0xFF6554C0);
  static const statusResolved = Color(0xFF00875A);
  static const statusClosed = Color(0xFF191B23);
  static const statusRejected = Color(0xFFDE350B);

  // Category colors
  static const catInfrastructure = Color(0xFFFF8B00);
  static const catLighting = Color(0xFFFFD700);
  static const catWaste = Color(0xFF00875A);
  static const catEnvironment = Color(0xFF36B37E);
  static const catWater = Color(0xFF0065FF);
  static const catTransport = Color(0xFF6554C0);
  static const catSafety = Color(0xFFDE350B);
}

/// Dark-mode counterpart of [AppColors]. Same field names/shape so screens
/// migrating to theme-driven styling can switch between the two via
/// `Theme.of(context).brightness` without changing call sites.
class AppColorsDark {
  AppColorsDark._();

  // Living gradient stops — muted/deepened for a night feel, same flow.
  static const gradientOrange = Color(0xFF7A4A38);
  static const gradientYellow = Color(0xFF7A6C3C);
  static const gradientGreen = Color(0xFF3D6B4C);
  static const gradientBlue = Color(0xFF3A5E72);

  // Ink — inverted: near-white text/CTAs on dark floating cards
  static const ink = Color(0xFFEDEEE8);
  static const inkSoft = Color(0xFFB8BAAE);

  // Semantic accents — brightened for dark backgrounds
  static const urgent = Color(0xFFFF8465);
  static const urgentSoft = Color(0xFF4A2A20);
  static const info = Color(0xFF6FA2FF);
  static const infoSoft = Color(0xFF1E2B4A);
  static const safe = Color(0xFF4FDB94);
  static const safeSoft = Color(0xFF16382A);

  // Brand (legacy — kept only for any not-yet-migrated reference)
  static const primary = Color(0xFF3D63D9);
  static const primaryLight = Color(0xFF6B87E8);
  static const primaryContainer = Color(0xFF1A2B63);

  // Accent — superseded by the v2 system above.
  static const accentStart = Color(0xFF00BFA6);
  static const accentEnd = Color(0xFFB0E63C);

  // Background / Surface
  static const background = Color(0xFF14151E);
  static const surface = Color(0xFF1C1E2A);
  static const surfaceVariant = Color(0xFF262838);
  static const surfaceContainer = Color(0xFF20222E);

  // Text
  static const textPrimary = Color(0xFFEDEEF5);
  static const textSecondary = Color(0xFF9EA2BE);
  static const textHint = Color(0xFF6C7093);

  // Border
  static const border = Color(0xFF3A3D54);
  static const divider = Color(0xFF2A2C3D);

  // Status (legacy — superseded by urgent/info/safe above)
  static const success = Color(0xFF36D399);
  static const successContainer = Color(0xFF0F3D2E);
  static const warning = Color(0xFFFFA53D);
  static const warningContainer = Color(0xFF4A3413);
  static const error = Color(0xFFFF6B57);
  static const errorContainer = Color(0xFF4A1F17);

  // Report status colors
  static const statusSubmitted = Color(0xFF9EA2BE);
  static const statusReceived = Color(0xFF4C8DFF);
  static const statusUnderReview = Color(0xFFFFA53D);
  static const statusInProgress = Color(0xFF8A7CE0);
  static const statusResolved = Color(0xFF36D399);
  static const statusClosed = Color(0xFFEDEEF5);
  static const statusRejected = Color(0xFFFF6B57);

  // Category colors — same hues as light, brightened for dark backgrounds.
  static const catInfrastructure = Color(0xFFFFA53D);
  static const catLighting = Color(0xFFFFE14D);
  static const catWaste = Color(0xFF36D399);
  static const catEnvironment = Color(0xFF5FE0A8);
  static const catWater = Color(0xFF4C8DFF);
  static const catTransport = Color(0xFF8A7CE0);
  static const catSafety = Color(0xFFFF6B57);
}
