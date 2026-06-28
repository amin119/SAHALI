import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';

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

  Color get color {
    switch (this) {
      case ReportStatus.submitted:
        return AppColors.statusSubmitted;
      case ReportStatus.received:
        return AppColors.statusReceived;
      case ReportStatus.underReview:
        return AppColors.statusUnderReview;
      case ReportStatus.inProgress:
        return AppColors.statusInProgress;
      case ReportStatus.resolved:
        return AppColors.statusResolved;
      case ReportStatus.rejected:
        return AppColors.statusRejected;
    }
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status.label(l10n),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: status.color,
        ),
      ),
    );
  }
}
