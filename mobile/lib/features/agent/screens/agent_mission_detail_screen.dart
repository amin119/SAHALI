import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/category_utils.dart';
import '../../../features/report/providers/reports_provider.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/report_detail_widgets.dart';
import '../../../shared/widgets/sa_button.dart';
import '../../../shared/widgets/sa_bottom_sheet.dart';
import '../widgets/resolve_mission_sheet.dart';

class AgentMissionDetailScreen extends StatefulWidget {
  const AgentMissionDetailScreen({super.key, this.reportId});
  final String? reportId;

  @override
  State<AgentMissionDetailScreen> createState() => _AgentMissionDetailScreenState();
}

class _AgentMissionDetailScreenState extends State<AgentMissionDetailScreen> {
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    if (widget.reportId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ReportsProvider>().loadReport(widget.reportId!);
      });
    }
  }

  Future<void> _advanceStatus(String nextStatus) async {
    final l10n = AppLocalizations.of(context);
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => _NotePromptDialog(
        title: l10n.agentNoteOptionalLabel,
        required: false,
      ),
    );
    if (note == null) return; // cancelled
    await _submitStatus(nextStatus, note.isEmpty ? null : note);
  }

  Future<void> _reject() async {
    final l10n = AppLocalizations.of(context);
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => _NotePromptDialog(
        title: l10n.agentRejectReasonLabel,
        required: true,
      ),
    );
    if (reason == null || reason.isEmpty) return;
    await _submitStatus('rejected', reason);
  }

  Future<void> _submitStatus(String status, String? note) async {
    setState(() => _updating = true);
    final ok = await context.read<ReportsProvider>().updateStatus(
          widget.reportId!,
          status,
          note: note,
        );
    if (!mounted) return;
    setState(() => _updating = false);
    if (!ok) {
      final error = context.read<ReportsProvider>().error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  Future<void> _openResolveSheet() async {
    final result = await showSaBottomSheet<bool>(
      context,
      builder: (_) => ResolveMissionSheet(reportId: widget.reportId!),
    );
    if (result == true && mounted) {
      await context.read<ReportsProvider>().loadReport(widget.reportId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportsProvider>();
    final l10n = AppLocalizations.of(context);
    final p = AppPalette.of(context);

    if (provider.loadingDetail) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (provider.error != null || provider.selectedReport == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(PhosphorIconsRegular.arrowLeft),
            onPressed: () => context.go(AppRoutes.agentMissions),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIconsRegular.warningCircle, size: 48, color: p.textHint),
              const SizedBox(height: 12),
              Text(provider.error ?? l10n.reportNotFound, style: TextStyle(color: p.textHint)),
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

    final report = provider.selectedReport!;
    final cat = provider.categoryById(report.categoryId);
    final slug = cat?.slug ?? 'infrastructure';
    final catColor = categoryColorBySlug(slug);
    final catIcon = categoryIconData(cat?.icon);
    final langCode = Localizations.localeOf(context).languageCode;
    final catLabel = categoryLabelBySlug(slug, langCode, apiLabel: cat?.labelFor(langCode) ?? l10n.reportFallback);
    final status = ReportStatusX.fromApi(report.status);
    final isClosed = report.isResolved || report.isClosed;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                child: const Icon(PhosphorIconsBold.arrowLeft, color: Colors.white, size: 18),
              ),
              onPressed: () => context.go(AppRoutes.agentMissions),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: report.displayPhotoUrls.isNotEmpty
                  ? PhotoHero(urls: report.displayPhotoUrls)
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
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p.textPrimary, height: 1.3),
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
                        Icon(PhosphorIconsRegular.mapPin, size: 14, color: p.textHint),
                        const SizedBox(width: 4),
                        Text(
                          report.address ?? report.city ?? '',
                          style: TextStyle(fontSize: 13, color: p.textHint),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(PhosphorIconsRegular.clock, size: 14, color: p.textHint),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('d MMM y · HH:mm').format(report.createdAt.toLocal()),
                        style: TextStyle(fontSize: 13, color: p.textHint),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Clipboard.setData(ClipboardData(text: report.trackingCode)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: AppShapes.card(color: p.infoSoft, radius: AppShapes.radiusPill),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsRegular.hash, size: 14, color: p.info),
                          const SizedBox(width: 6),
                          Text(
                            report.trackingCode,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.info, letterSpacing: 1),
                          ),
                          const SizedBox(width: 8),
                          Icon(PhosphorIconsRegular.copySimple, size: 13, color: p.info),
                        ],
                      ),
                    ),
                  ),

                  if (report.description != null && report.description!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    SectionTitle(l10n.reviewDescription),
                    const SizedBox(height: 8),
                    Text(
                      report.description!,
                      style: TextStyle(fontSize: 14, color: p.textPrimary, height: 1.6),
                    ),
                  ],

                  if (report.history.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    SectionTitle(l10n.statusTimeline),
                    const SizedBox(height: 12),
                    ...List.generate(report.history.length, (i) {
                      final step = report.history[i];
                      final isLast = i == report.history.length - 1;
                      final stepStatus = ReportStatusX.fromApi(step.toStatus);
                      return TimelineRow(
                        status: stepStatus,
                        date: DateFormat('d MMM · HH:mm').format(step.createdAt.toLocal()),
                        note: step.note ?? stepStatus.toString().split('.').last,
                        isLast: isLast,
                        isActive: isLast,
                      );
                    }),
                  ],

                  const SizedBox(height: 32),

                  if (isClosed)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: AppShapes.card(color: p.surfaceVariant, radius: AppShapes.radiusLg),
                      child: Text(
                        l10n.agentMissionClosed,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.textHint),
                      ),
                    )
                  else ...[
                    SaButton(
                      label: switch (report.status) {
                        'received' => l10n.agentAdvanceToReview,
                        'under_review' => l10n.agentAdvanceToProgress,
                        _ => l10n.agentResolveCta,
                      },
                      isLoading: _updating,
                      onPressed: switch (report.status) {
                        'received' => () => _advanceStatus('under_review'),
                        'under_review' => () => _advanceStatus('in_progress'),
                        'in_progress' => _openResolveSheet,
                        _ => null,
                      },
                    ),
                    const SizedBox(height: 12),
                    SaOutlinedButton(
                      label: l10n.agentRejectCta,
                      onPressed: _updating ? null : _reject,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small optional/required note prompt used for the two plain status
/// advances and for the reject reason — visually distinct from the resolve
/// bottom sheet, since these are much lower-stakes one-tap actions.
class _NotePromptDialog extends StatefulWidget {
  const _NotePromptDialog({required this.title, required this.required});
  final String title;
  final bool required;

  @override
  State<_NotePromptDialog> createState() => _NotePromptDialogState();
}

class _NotePromptDialogState extends State<_NotePromptDialog> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _ctrl,
        maxLines: 3,
        autofocus: true,
        decoration: InputDecoration(errorText: _error),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () {
            final text = _ctrl.text.trim();
            if (widget.required && text.isEmpty) {
              setState(() => _error = l10n.agentRejectReasonRequired);
              return;
            }
            Navigator.of(context).pop(text);
          },
          child: Text(l10n.agentConfirm),
        ),
      ],
    );
  }
}
