import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/category_utils.dart';
import '../../../features/report/providers/reports_provider.dart';
import '../../../shared/widgets/status_badge.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({super.key, this.reportId});
  final String? reportId;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.reportId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ReportsProvider>().loadReport(widget.reportId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportsProvider>();

    if (provider.loadingDetail) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.error != null || provider.selectedReport == null) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go(AppRoutes.myReports))),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text(provider.error ?? l10n.reportNotFound, style: const TextStyle(color: AppColors.textHint)),
              const SizedBox(height: 12),
              if (widget.reportId != null)
                TextButton(
                  onPressed: () => provider.loadReport(widget.reportId!),
                  child: Text(l10n.retry),
                ),
            ],
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    final report = provider.selectedReport!;
    final cat = provider.categoryById(report.categoryId);
    final slug = cat?.slug ?? 'infrastructure';
    final catColor = categoryColorBySlug(slug);
    final catIcon = categoryIconData(cat?.icon);
    final catLabel = cat?.labelFor(Localizations.localeOf(context).languageCode) ?? l10n.reportFallback;
    final status = ReportStatusX.fromApi(report.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
              ),
              onPressed: () => context.go(AppRoutes.myReports),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: report.displayPhotoUrls.isNotEmpty
                  ? _PhotoHero(urls: report.displayPhotoUrls)
                  : Container(
                      color: catColor.withValues(alpha: 0.15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(catIcon, color: catColor, size: 64),
                          const SizedBox(height: 8),
                          Text(catLabel, style: TextStyle(color: catColor, fontWeight: FontWeight.w700, fontSize: 14)),
                        ],
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          report.title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      StatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (report.address != null || report.city != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          report.address ?? report.city ?? '',
                          style: const TextStyle(fontSize: 13, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('d MMM y · HH:mm').format(report.createdAt.toLocal()),
                        style: const TextStyle(fontSize: 13, color: AppColors.textHint),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Clipboard.setData(ClipboardData(text: report.trackingCode)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tag_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            report.trackingCode,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.copy_rounded, size: 13, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),

                  if (report.description != null && report.description!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionTitle(l10n.reviewDescription),
                    const SizedBox(height: 8),
                    Text(
                      report.description!,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.6),
                    ),
                  ],

                  if (report.history.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionTitle(l10n.statusTimeline),
                    const SizedBox(height: 12),
                    ...List.generate(report.history.length, (i) {
                      final step = report.history[i];
                      final isLast = i == report.history.length - 1;
                      final stepStatus = ReportStatusX.fromApi(step.toStatus);
                      return _TimelineRow(
                        status: stepStatus,
                        date: DateFormat('d MMM · HH:mm').format(step.createdAt.toLocal()),
                        note: step.note ?? stepStatus.toString().split('.').last,
                        isLast: isLast,
                        isActive: isLast,
                      );
                    }),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textHint, letterSpacing: 0.8),
  );
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.status,
    required this.date,
    required this.note,
    required this.isLast,
    required this.isActive,
  });
  final ReportStatus status;
  final String date, note;
  final bool isLast, isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? status.color : AppColors.divider;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    color: isActive ? color : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColors.divider, margin: const EdgeInsets.symmetric(vertical: 4)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusBadge(status: status),
                  const SizedBox(height: 4),
                  Text(note, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                  const SizedBox(height: 2),
                  Text(date, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Photo hero: swipeable when multiple photos ────────────────────────────────

class _PhotoHero extends StatefulWidget {
  const _PhotoHero({required this.urls});
  final List<String> urls;
  @override
  State<_PhotoHero> createState() => _PhotoHeroState();
}

class _PhotoHeroState extends State<_PhotoHero> {
  int _current = 0;
  late final PageController _ctrl = PageController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _ctrl,
          itemCount: widget.urls.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (_, i) => Image.network(
            widget.urls[i],
            fit: BoxFit.cover,
            headers: const {'ngrok-skip-browser-warning': '1'},
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: Color(0xFFe8edf2),
              child: Icon(Icons.broken_image_outlined, size: 40, color: Color(0xFF94A3B8)),
            ),
          ),
        ),
        if (widget.urls.length > 1)
          Positioned(
            bottom: 10, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.urls.length, (i) => Container(
                width: _current == i ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _current == i ? Colors.white : Colors.white54,
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
          ),
      ],
    );
  }
}
