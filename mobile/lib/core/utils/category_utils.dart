import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_colors.dart';

IconData categoryIconData(String? iconName) {
  switch (iconName) {
    case 'construction':
      return PhosphorIconsDuotone.hammer;
    case 'light':
    case 'lightbulb':
      return PhosphorIconsDuotone.lightbulb;
    case 'delete_forever':
    case 'delete':
      return PhosphorIconsDuotone.trash;
    case 'park':
    case 'eco':
    case 'nature':
      return PhosphorIconsDuotone.tree;
    case 'water':
    case 'water_drop':
      return PhosphorIconsDuotone.drop;
    case 'drain':
    case 'plumbing':
      return PhosphorIconsDuotone.wrench;
    case 'directions_bus':
    case 'bus':
      return PhosphorIconsDuotone.bus;
    case 'shield':
    case 'security':
      return PhosphorIconsDuotone.shieldCheck;
    case 'signpost':
      return PhosphorIconsDuotone.signpost;
    case 'directions_walk':
      return PhosphorIconsDuotone.personSimpleWalk;
    case 'warning':
    case 'report':
    default:
      return PhosphorIconsDuotone.warningCircle;
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
