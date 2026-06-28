import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
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

  static const _statusFilters = [null, 'active', 'resolved', 'rejected'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().loadMyReports(refresh: true);
    });
  }

  String? _apiStatus() {
    if (_filterIndex == 0) return null;
    // API accepts individual status values; we filter client-side for grouped tabs
    return null;
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.myReports),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.home),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
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
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: active ? AppColors.primary : AppColors.divider),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      filters[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppColors.textSecondary,
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
                            const Icon(Icons.wifi_off_rounded, color: AppColors.textHint, size: 40),
                            const SizedBox(height: 12),
                            Text(provider.error!, style: const TextStyle(color: AppColors.textHint, fontSize: 14)),
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
                                Icon(Icons.inbox_outlined, size: 56, color: AppColors.textHint.withValues(alpha: 0.5)),
                                const SizedBox(height: 12),
                                Text(l10n.noReportsFound, style: const TextStyle(fontSize: 15, color: AppColors.textHint)),
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
  const _ReportCard({required this.report, required this.provider, required this.onTap});
  final ReportModel report;
  final ReportsProvider provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cat = provider.categoryById(report.categoryId);
    final slug = cat?.slug ?? 'infrastructure';
    final color = categoryColorBySlug(slug);
    final icon = categoryIconData(cat?.icon);
    final catLabel = cat?.labelFor(Localizations.localeOf(context).languageCode) ?? 'Report';
    final status = ReportStatusX.fromApi(report.status);
    final dateStr = DateFormat('d MMM y').format(report.createdAt.toLocal());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(catLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                      Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                    ],
                  ),
                ),
                StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              report.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.address ?? report.city ?? '${report.lat?.toStringAsFixed(4) ?? ''}, ${report.lng?.toStringAsFixed(4) ?? ''}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  report.trackingCode,
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontFamily: 'monospace'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
