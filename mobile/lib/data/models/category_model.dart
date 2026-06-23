class CategoryModel {
  final int id;
  final int? parentId;
  final String slug;
  final String labelFr;
  final String labelAr;
  final String labelEn;
  final String? icon;
  final int? slaHours;
  final List<CategoryModel> children;

  const CategoryModel({
    required this.id,
    this.parentId,
    required this.slug,
    required this.labelFr,
    required this.labelAr,
    required this.labelEn,
    this.icon,
    this.slaHours,
    this.children = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> j) => CategoryModel(
        id: j['id'] as int,
        parentId: j['parent_id'] as int?,
        slug: j['slug'] as String,
        labelFr: j['label_fr'] as String,
        labelAr: j['label_ar'] as String,
        labelEn: j['label_en'] as String,
        icon: j['icon'] as String?,
        slaHours: j['sla_hours'] as int?,
        children: (j['children'] as List<dynamic>? ?? [])
            .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

  String labelFor(String langCode) {
    switch (langCode) {
      case 'ar':
        return labelAr;
      case 'en':
        return labelEn;
      default:
        return labelFr;
    }
  }

  String get rootSlug => slug.split('.').first;
}
