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
import '../../../data/models/report_model.dart';
import '../../../features/report/providers/reports_provider.dart';
import '../../../shared/widgets/status_badge.dart';
import 'package:intl/intl.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});
  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  int _filterIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().loadMyReports(refresh: true);
    });
  }

  List<ReportModel> _filtered(List<ReportModel> all) {
    if (_filterIndex == 0) return all;
    return all.where((r) {
      if (_filterIndex == 1) return r.isActive;
      if (_filterIndex == 2) return r.isResolved;
      if (_filterIndex == 3) return r.isClosed;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<ReportsProvider>();
    final filters = [
      l10n.filterAll,
      l10n.filterActive,
      l10n.filterResolved,
      l10n.filterClosed,
    ];
    final filtered = _filtered(provider.reports);
    final p = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.myReports),
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.go(AppRoutes.home),
        ),
        actions: [
          IconButton(
            icon: Icon(PhosphorIconsRegular.plus),
            onPressed: () => context.go(AppRoutes.reportCategory),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filters.length,
              itemBuilder: (_, i) {
                final active = _filterIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _filterIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: AppShapes.card(
                      color: active ? p.ink : p.surface,
                      radius: AppShapes.radiusPill,
                      borderColor: active ? p.ink : p.divider,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      filters[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : p.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: provider.loading && provider.reports.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null && provider.reports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(PhosphorIconsRegular.wifiSlash, color: p.textHint, size: 40),
                            const SizedBox(height: 12),
                            Text(provider.error!, style: TextStyle(color: p.textHint, fontSize: 14)),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => provider.loadMyReports(refresh: true),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(PhosphorIconsDuotone.tray, size: 56, color: p.textHint.withValues(alpha: 0.5)),
                                const SizedBox(height: 12),
                                Text(l10n.noReportsFound, style: TextStyle(fontSize: 15, color: p.textHint)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => provider.loadMyReports(refresh: true),
                            child: ListView.builder(
                              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) => _ReportCard(
                                report: filtered[i],
                                provider: provider,
                                onTap: () => context.go('/report/${filtered[i].id}'),
                                index: i,
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.provider, required this.onTap, this.index = 0});
  final ReportModel report;
  final ReportsProvider provider;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final cat = provider.categoryById(report.categoryId);
    final slug = cat?.slug ?? 'infrastructure';
    final color = categoryColorBySlug(slug);
    final icon = categoryIconData(cat?.icon);
    final langCode = Localizations.localeOf(context).languageCode;
    final catLabel = categoryLabelBySlug(slug, langCode, apiLabel: cat?.labelFor(langCode) ?? 'Report');
    final status = ReportStatusX.fromApi(report.status);
    final dateStr = DateFormat('d MMM y').format(report.createdAt.toLocal());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: AppShapes.card(color: p.surface, radius: AppShapes.radiusLg, borderColor: p.divider),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: AppShapes.card(color: color.withValues(alpha: 0.12), radius: AppShapes.radiusSm),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(catLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.textHint)),
                      Text(dateStr, style: TextStyle(fontSize: 11, color: p.textHint)),
                    ],
                  ),
                ),
                StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              report.title,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(PhosphorIconsRegular.mapPin, size: 13, color: p.textHint),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.address ?? report.city ?? '${report.lat?.toStringAsFixed(4) ?? ''}, ${report.lng?.toStringAsFixed(4) ?? ''}',
                    style: TextStyle(fontSize: 12, color: p.textHint),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  report.trackingCode,
                  style: TextStyle(fontSize: 11, color: p.textHint, fontFamily: 'monospace'),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 260.ms, delay: (40 * index).ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
  }
}
