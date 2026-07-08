import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/utils/category_utils.dart';
import '../../../data/models/category_model.dart';
import '../../../data/services/category_service.dart';
import '../../../shared/widgets/sa_button.dart';
import '../../../shared/widgets/step_bar.dart';
import '../viewmodels/report_form_provider.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});
  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  int? _selected;
  List<CategoryModel> _categories = [];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    final saved = context.read<ReportFormProvider>().categoryIndex;
    if (saved != null) _selected = saved;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await CategoryService().listCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _loadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  void _confirm() {
    if (_selected == null || _selected! >= _categories.length) return;
    final cat = _categories[_selected!];
    final icon = categoryIconData(cat.icon);
    final color = categoryColorBySlug(cat.slug);
    final langCode = Localizations.localeOf(context).languageCode;
    context.read<ReportFormProvider>().setCategory(
          _selected!,
          cat.labelFor(langCode),
          icon,
          color,
          id: cat.id,
        );
    context.go(AppRoutes.reportPhoto);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final isRtl = langCode == 'ar';
    final textDir = isRtl ? TextDirection.rtl : TextDirection.ltr;
    final p = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.newReport),
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.x),
          onPressed: () => context.go(AppRoutes.home),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: StepBar(step: 1, total: 6),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.whatReporting,
              textDirection: textDir,
              style: Theme.of(context).textTheme.headlineLarge,
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 4),
            Text(
              l10n.chooseCategoryHint,
              textDirection: textDir,
              style: TextStyle(fontSize: 14, color: p.textSecondary),
            ).animate().fadeIn(duration: 300.ms, delay: 60.ms),
            const SizedBox(height: 24),
            Expanded(
              child: _loadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : _categories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(PhosphorIconsRegular.wifiSlash, color: p.textHint, size: 40),
                              const SizedBox(height: 12),
                              Text(l10n.couldNotLoadCategories, style: TextStyle(color: p.textHint)),
                              const SizedBox(height: 12),
                              TextButton(onPressed: _loadCategories, child: Text(l10n.retry)),
                            ],
                          ),
                        )
                      : Builder(
                          builder: (ctx) {
                            final langCode = Localizations.localeOf(ctx).languageCode;
                            final isRtl = langCode == 'ar';
                            final textDir = isRtl ? TextDirection.rtl : TextDirection.ltr;
                            return Directionality(
                              textDirection: textDir,
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1.1,
                                ),
                                itemCount: _categories.length,
                                itemBuilder: (_, i) {
                                  final cat = _categories[i];
                                  final isSelected = _selected == i;
                                  final color = categoryColorBySlug(cat.slug);
                                  final icon = categoryIconData(cat.icon);
                                  return GestureDetector(
                                    onTap: () => setState(() => _selected = i),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      decoration: AppShapes.card(
                                        gradient: isSelected
                                            ? LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [color.withValues(alpha: 0.16), color.withValues(alpha: 0.06)],
                                              )
                                            : null,
                                        color: isSelected ? null : p.surface,
                                        radius: AppShapes.radiusLg,
                                        borderColor: isSelected ? color : p.divider,
                                        borderWidth: isSelected ? 2 : 1,
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          AnimatedScale(
                                            scale: isSelected ? 1.08 : 1.0,
                                            duration: const Duration(milliseconds: 200),
                                            curve: Curves.easeOutBack,
                                            child: Container(
                                              width: 44,
                                              height: 44,
                                              decoration: AppShapes.card(color: color.withValues(alpha: 0.14), radius: AppShapes.radiusSm),
                                              child: Icon(icon, color: color, size: 22),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            cat.labelFor(langCode),
                                            textDirection: textDir,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: p.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            cat.children.isNotEmpty
                                                ? l10n.subCategoriesCount(cat.children.length)
                                                : cat.slug,
                                            textDirection: textDir,
                                            style: TextStyle(fontSize: 11, color: p.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ).animate().fadeIn(
                                        duration: 280.ms,
                                        delay: (30 * i).ms,
                                      ).slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
                                },
                              ),
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: SaButton(
                label: l10n.nextPhoto,
                onPressed: _selected == null ? null : _confirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
