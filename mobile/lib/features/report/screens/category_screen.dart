import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.newReport),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
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
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.chooseCategoryHint,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _loadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : _categories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.wifi_off_rounded, color: AppColors.textHint, size: 40),
                              const SizedBox(height: 12),
                              const Text('Could not load categories', style: TextStyle(color: AppColors.textHint)),
                              const SizedBox(height: 12),
                              TextButton(onPressed: _loadCategories, child: const Text('Retry')),
                            ],
                          ),
                        )
                      : GridView.builder(
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
                            final langCode = Localizations.localeOf(context).languageCode;
                            return GestureDetector(
                              onTap: () => setState(() => _selected = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? color.withValues(alpha: 0.10)
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? color : AppColors.divider,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(icon, color: color, size: 22),
                                    ),
                                    const Spacer(),
                                    Text(
                                      cat.labelFor(langCode),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      cat.children.isNotEmpty
                                          ? '${cat.children.length} sub-categories'
                                          : cat.slug,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
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
