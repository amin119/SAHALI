import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

IconData categoryIconData(String? iconName) {
  switch (iconName) {
    case 'construction':
      return Icons.construction_rounded;
    case 'light':
    case 'lightbulb':
      return Icons.lightbulb_outline_rounded;
    case 'delete_forever':
    case 'delete':
      return Icons.delete_outline_rounded;
    case 'park':
    case 'eco':
    case 'nature':
      return Icons.park_outlined;
    case 'water':
    case 'water_drop':
      return Icons.water_drop_outlined;
    case 'drain':
    case 'plumbing':
      return Icons.plumbing_outlined;
    case 'directions_bus':
    case 'bus':
      return Icons.directions_bus_outlined;
    case 'shield':
    case 'security':
      return Icons.shield_outlined;
    case 'signpost':
      return Icons.signpost_outlined;
    case 'directions_walk':
      return Icons.directions_walk_rounded;
    case 'warning':
    case 'report':
    default:
      return Icons.report_problem_outlined;
  }
}

Color categoryColorBySlug(String slug) {
  final root = slug.split('.').first;
  switch (root) {
    case 'infrastructure':
      return AppColors.catInfrastructure;
    case 'lighting':
      return AppColors.catLighting;
    case 'waste':
      return AppColors.catWaste;
    case 'environment':
    case 'green':
      return AppColors.catEnvironment;
    case 'water':
      return AppColors.catWater;
    case 'transport':
      return AppColors.catTransport;
    case 'safety':
    case 'security':
      return AppColors.catSafety;
    default:
      return AppColors.primary;
  }
}

// Fallback color by category index (for lists without slug info)
Color categoryColorByIndex(int index) {
  const colors = [
    AppColors.catInfrastructure,
    AppColors.catLighting,
    AppColors.catWaste,
    AppColors.catEnvironment,
    AppColors.catWater,
    AppColors.catTransport,
    AppColors.catSafety,
  ];
  return colors[index % colors.length];
}
