import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF0038AF);
  static const primaryLight = Color(0xFF1B4FD8);
  static const primaryContainer = Color(0xFFDCE1FF);

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

  // Status
  static const success = Color(0xFF00875A);
  static const successContainer = Color(0xFFE3FCEF);
  static const warning = Color(0xFFFF8B00);
  static const warningContainer = Color(0xFFFFF4E5);
  static const error = Color(0xFFDE350B);
  static const errorContainer = Color(0xFFFFEDEB);
  static const info = Color(0xFF0065FF);
  static const infoContainer = Color(0xFFDEEBFF);

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
