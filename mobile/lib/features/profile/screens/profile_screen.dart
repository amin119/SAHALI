import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/category_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/report/providers/reports_provider.dart';
import '../../../shared/widgets/status_badge.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().loadMyReports(refresh: true);
    });
  }

  void _showLanguagePicker(BuildContext context, AppLocalizations l10n) {
    final lang = context.read<LanguageProvider>();
    final langs = [
      ('fr', 'Français', '🇫🇷'),
      ('ar', 'العربية', '🇹🇳'),
      ('en', 'English', '🇬🇧'),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(l10n.language, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            ...langs.map((t) {
              final (code, label, flag) = t;
              final selected = lang.languageCode == code;
              return ListTile(
                leading: Text(flag, style: const TextStyle(fontSize: 22)),
                title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? AppColors.primary : AppColors.textPrimary)),
                trailing: selected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                onTap: () { lang.setLocale(code); Navigator.pop(context); },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: selected ? AppColors.primaryContainer : Colors.transparent,
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = context.watch<LanguageProvider>().languageCode;
    final langLabel = langCode == 'fr' ? 'Français' : langCode == 'ar' ? 'العربية' : 'English';
    final auth = context.watch<AuthProvider>();
    final reports = context.watch<ReportsProvider>();

    final user = auth.user;
    final totalReports = reports.total;
    final resolvedCount = reports.reports.where((r) => r.isResolved).length;
    final activeCount = reports.reports.where((r) => r.isActive).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(l10n.profile),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.go(AppRoutes.home),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar + name
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
                              child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 40),
                            ),
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                width: 26, height: 26,
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          user?.fullName ?? 'Guest',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        if (user?.phone != null)
                          Text(user!.phone!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))
                        else if (user?.email != null)
                          Text(user!.email!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        if (user != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(100)),
                            child: Text(
                              user.role == 'citizen' ? 'Citizen' : user.role,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats
                  Row(
                    children: [
                      _StatCard(value: '$totalReports', label: l10n.myReports, icon: Icons.flag_outlined, color: AppColors.primary),
                      const SizedBox(width: 12),
                      _StatCard(value: '$resolvedCount', label: l10n.resolvedLabel, icon: Icons.check_circle_outline_rounded, color: AppColors.success),
                      const SizedBox(width: 12),
                      _StatCard(value: '$activeCount', label: l10n.activeLabel, icon: Icons.pending_outlined, color: AppColors.statusInProgress),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent activity
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(l10n.recentActivitySection, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  ),
                  const SizedBox(height: 12),

                  ...reports.reports.take(3).map((r) {
                    final cat = reports.categoryById(r.categoryId);
                    final slug = cat?.slug ?? 'infrastructure';
                    return _ActivityRow(
                      icon: categoryIconData(cat?.icon),
                      color: categoryColorBySlug(slug),
                      title: r.title,
                      status: ReportStatusX.fromApi(r.status),
                      date: DateFormat('d MMM y').format(r.createdAt.toLocal()),
                    );
                  }),

                  if (reports.reports.isEmpty && !reports.loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No reports yet.', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                    ),

                  TextButton(
                    onPressed: () => context.go(AppRoutes.myReports),
                    child: Text(l10n.viewAllReports),
                  ),

                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),

                  _SettingsTile(icon: Icons.notifications_outlined, label: l10n.notifications, onTap: () {}),
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    label: l10n.language,
                    trailing: langLabel,
                    onTap: () => _showLanguagePicker(context, l10n),
                  ),
                  _SettingsTile(icon: Icons.privacy_tip_outlined, label: l10n.privacyPolicy, onTap: () {}),
                  _SettingsTile(icon: Icons.help_outline_rounded, label: l10n.helpSupport, onTap: () {}),
                  _SettingsTile(
                    icon: Icons.logout_rounded,
                    label: l10n.signOut,
                    textColor: AppColors.error,
                    onTap: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go(AppRoutes.login);
                    },
                  ),
                  const SizedBox(height: 32),
                  const Text('سهلي v1.0.0', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, required this.icon, required this.color});
  final String value, label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
        ],
      ),
    ),
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.icon, required this.color, required this.title, required this.status, required this.date});
  final IconData icon;
  final Color color;
  final String title, date;
  final ReportStatus status;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
    child: Row(
      children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(date, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        StatusBadge(status: status),
      ],
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.label, required this.onTap, this.trailing, this.textColor});
  final IconData icon;
  final String label;
  final String? trailing;
  final Color? textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? AppColors.textPrimary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      trailing: trailing != null
          ? Text(trailing!, style: const TextStyle(fontSize: 13, color: AppColors.textHint))
          : const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}
