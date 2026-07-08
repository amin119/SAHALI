import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/notification_settings_provider.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppPalette.of(context);
    final settings = context.watch<NotificationSettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.notificationSettingsTitle),
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppShapes.card(color: p.surface, radius: AppShapes.radiusLg, borderColor: p.divider),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: AppShapes.card(color: p.infoSoft, radius: AppShapes.radiusMd),
                  child: Icon(PhosphorIconsDuotone.bellRinging, color: p.info, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.pushNotifications, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.textPrimary)),
                      const SizedBox(height: 2),
                      Text(l10n.pushNotificationsDesc, style: TextStyle(fontSize: 12, color: p.textSecondary, height: 1.4)),
                    ],
                  ),
                ),
                Switch(
                  value: settings.pushEnabled,
                  onChanged: (v) async {
                    settings.setPushEnabled(v);
                    if (v) await LocalNotificationService.instance.requestPermissionIfNeeded();
                  },
                  activeThumbColor: p.ink,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(l10n.notifyMeAbout, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textHint, letterSpacing: 0.4)),
          const SizedBox(height: 12),

          Container(
            decoration: AppShapes.card(color: p.surface, radius: AppShapes.radiusLg, borderColor: p.divider),
            child: Column(
              children: [
                for (final status in ReportStatus.values) ...[
                  _StatusToggle(status: status, enabled: settings.pushEnabled),
                  if (status != ReportStatus.values.last)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 1, color: p.divider),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  const _StatusToggle({required this.status, required this.enabled});
  final ReportStatus status;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppPalette.of(context);
    final settings = context.watch<NotificationSettingsProvider>();
    final color = status.color(p);
    final checked = settings.isStatusEnabled(status);

    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Container(
          width: 34,
          height: 34,
          decoration: AppShapes.card(color: color.withValues(alpha: 0.12), radius: AppShapes.radiusSm),
          child: Icon(status.icon, color: color, size: 17),
        ),
        title: Text(status.label(l10n), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.textPrimary)),
        trailing: Switch(
          value: checked,
          onChanged: enabled ? (_) => settings.toggleStatus(status) : null,
          activeThumbColor: color,
        ),
      ),
    );
  }
}
