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

// Category display labels, hardcoded per language. The backend/dashboard
// both show these correctly, but Arabic labels fetched over the API and
// rendered on-device came through with scrambled letter order on some
// devices — this sidesteps whatever is happening in that data path for
// this small, stable set of 7 root categories.
const Map<String, Map<String, String>> _categoryLabels = {
  'infrastructure': {
    'fr': 'Infrastructure',
    'ar': 'البنية التحتية',
    'en': 'Infrastructure',
  },
  'lighting': {
    'fr': 'Éclairage',
    'ar': 'الإنارة العامة',
    'en': 'Lighting',
  },
  'waste': {
    'fr': 'Déchets',
    'ar': 'النظافة والنفايات',
    'en': 'Waste',
  },
  'environment': {
    'fr': 'Environnement',
    'ar': 'البيئة',
    'en': 'Environment',
  },
  'water_sanitation': {
    'fr': 'Eau et assainissement',
    'ar': 'المياه والصرف الصحي',
    'en': 'Water & Sanitation',
  },
  'transport': {
    'fr': 'Transport',
    'ar': 'النقل',
    'en': 'Transport',
  },
  'safety': {
    'fr': 'Sécurité',
    'ar': 'السلامة والأمن',
    'en': 'Safety',
  },
};

/// Looks up the display label for a category by its root slug, falling
/// back to [apiLabel] (the backend-provided value) if the slug isn't one
/// of the 7 known root categories.
String categoryLabelBySlug(String slug, String langCode, {String? apiLabel}) {
  var root = slug.split('.').first;
  if (root == 'water') root = 'water_sanitation';
  final entry = _categoryLabels[root];
  if (entry == null) return apiLabel ?? slug;
  return entry[langCode] ?? entry['fr']!;
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
