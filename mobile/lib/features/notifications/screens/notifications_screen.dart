import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<NotificationsProvider>();
    final p = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.notificationsTitle),
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.go(AppRoutes.home),
        ),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: provider.markAllRead,
              child: Text(l10n.markAllRead, style: const TextStyle(fontSize: 13)),
            ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIconsDuotone.bellSlash, size: 64, color: p.textHint.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(l10n.noNotifications, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.textPrimary)),
                      const SizedBox(height: 8),
                      Text(l10n.notificationsTitle, style: TextStyle(fontSize: 14, color: p.textSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: provider.load,
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
                    itemCount: provider.notifications.length,
                    itemBuilder: (_, i) {
                      final n = provider.notifications[i];
                      final status = ReportStatusX.inferFromText(n.title);
                      final statusColor = status.color(p);
                      return GestureDetector(
                        onTap: () {
                          if (!n.isRead) provider.markRead(n.id);
                          if (n.reportId != null) context.go('/report/${n.reportId}');
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: AppShapes.card(
                            color: n.isRead ? p.surface : statusColor.withValues(alpha: 0.08),
                            radius: AppShapes.radiusLg,
                            borderColor: n.isRead ? p.divider : statusColor.withValues(alpha: 0.3),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: AppShapes.card(
                                  color: statusColor.withValues(alpha: 0.12),
                                  radius: AppShapes.radiusMd,
                                ),
                                child: Icon(status.icon, color: statusColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.title, style: TextStyle(fontSize: 14, fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700, color: p.textPrimary)),
                                    const SizedBox(height: 3),
                                    Text(n.body, style: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(DateFormat('d MMM · HH:mm').format(n.createdAt.toLocal()), style: TextStyle(fontSize: 11, color: p.textHint)),
                                  ],
                                ),
                              ),
                              if (!n.isRead)
                                Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 260.ms, delay: (30 * i).ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
                    },
                  ),
                ),
    );
  }
}
