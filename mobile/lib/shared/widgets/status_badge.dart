import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_shapes.dart';

enum ReportStatus {
  submitted,
  received,
  underReview,
  inProgress,
  resolved,
  rejected,
}

extension ReportStatusX on ReportStatus {
  static ReportStatus fromApi(String value) {
    switch (value) {
      case 'submitted':
        return ReportStatus.submitted;
      case 'received':
        return ReportStatus.received;
      case 'under_review':
        return ReportStatus.underReview;
      case 'in_progress':
        return ReportStatus.inProgress;
      case 'resolved':
        return ReportStatus.resolved;
      case 'rejected':
        return ReportStatus.rejected;
      default:
        return ReportStatus.submitted;
    }
  }

  /// Best-effort classification of a notification's status from its title
  /// text, matching the fixed fr/en/ar phrases the backend templates use
  /// (see `backend/app/services/notification.py`). The notification API
  /// doesn't expose the raw status/event, so this is inferred client-side.
  static ReportStatus inferFromText(String text) {
    final t = text.toLowerCase();
    bool has(List<String> needles) => needles.any((n) => t.contains(n));
    if (has(['résolu', 'resolved', 'حل'])) return ReportStatus.resolved;
    if (has(['rejeté', 'rejected', 'رفض'])) return ReportStatus.rejected;
    if (has(['examen', 'review', 'دراسة'])) return ReportStatus.underReview;
    if (has(['intervention', 'progress', 'جار'])) return ReportStatus.inProgress;
    if (has(['pris en charge', 'acknowledged', 'تولي'])) return ReportStatus.received;
    return ReportStatus.submitted;
  }

  IconData get icon {
    switch (this) {
      case ReportStatus.submitted:
        return PhosphorIconsDuotone.tray;
      case ReportStatus.received:
        return PhosphorIconsDuotone.envelopeSimpleOpen;
      case ReportStatus.underReview:
        return PhosphorIconsDuotone.magnifyingGlass;
      case ReportStatus.inProgress:
        return PhosphorIconsDuotone.wrench;
      case ReportStatus.resolved:
        return PhosphorIconsDuotone.checkCircle;
      case ReportStatus.rejected:
        return PhosphorIconsDuotone.xCircle;
    }
  }

  String label(AppLocalizations l) {
    switch (this) {
      case ReportStatus.submitted:
        return l.statusSubmitted;
      case ReportStatus.received:
        return l.statusReceived;
      case ReportStatus.underReview:
        return l.statusUnderReview;
      case ReportStatus.inProgress:
        return l.statusInProgress;
      case ReportStatus.resolved:
        return l.statusResolved;
      case ReportStatus.rejected:
        return l.statusRejected;
    }
  }

  Color color(AppPalette p) {
    switch (this) {
      case ReportStatus.resolved:
        return p.safe;
      case ReportStatus.rejected:
        return p.urgent;
      case ReportStatus.submitted:
      case ReportStatus.received:
      case ReportStatus.underReview:
      case ReportStatus.inProgress:
        return p.info;
    }
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppPalette.of(context);
    final color = status.color(p);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: AppShapes.card(color: color.withValues(alpha: 0.12), radius: AppShapes.radiusPill),
      child: Text(
        status.label(l10n),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
