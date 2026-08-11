import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/tour/app_tour.dart';
import '../../../core/utils/category_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/report/providers/reports_provider.dart';
import '../../../shared/widgets/sa_bottom_sheet.dart';
import '../../../shared/widgets/sahali_header_logo.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/tour_button.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _settingsKey = GlobalKey();

  void _scrollToSettings() {
    final ctx = _settingsKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    }
  }

  void _showTour(AppLocalizations l10n) {
    showScreenTour(context, [
      TourStep(
        targetKey: _settingsKey,
        title: l10n.tourProfileMenuTitle,
        description: l10n.tourProfileMenuDesc,
        align: ContentAlign.top,
      ),
    ], doneLabel: l10n.tourDone);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().loadMyReports(refresh: true);
    });
  }

  void _showLanguagePicker(BuildContext context, AppLocalizations l10n) {
    final lang = context.read<LanguageProvider>();
    final p = AppPalette.of(context);
    final langs = [
      ('fr', 'Français', '🇫🇷'),
      ('ar', 'العربية', '🇹🇳'),
      ('en', 'English', '🇬🇧'),
    ];
    showSaBottomSheet(
      context,
      isScrollControlled: false,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.language, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.textPrimary)),
            const SizedBox(height: 16),
            ...langs.map((t) {
              final (code, label, flag) = t;
              final selected = lang.languageCode == code;
              return ListTile(
                leading: Text(flag, style: const TextStyle(fontSize: 22)),
                title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? p.info : p.textPrimary)),
                trailing: selected ? Icon(PhosphorIconsFill.checkCircle, color: p.info) : null,
                onTap: () { lang.setLocale(code); Navigator.pop(context); },
                shape: AppShapes.border(radius: AppShapes.radiusMd),
                tileColor: selected ? p.infoSoft : Colors.transparent,
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context, AppLocalizations l10n) {
    final themeProvider = context.read<ThemeProvider>();
    final p = AppPalette.of(context);
    final options = [
      (ThemeMode.system, l10n.themeSystem, PhosphorIconsRegular.circleHalf),
      (ThemeMode.light, l10n.themeLight, PhosphorIconsRegular.sun),
      (ThemeMode.dark, l10n.themeDark, PhosphorIconsRegular.moon),
    ];
    showSaBottomSheet(
      context,
      isScrollControlled: false,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.theme, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.textPrimary)),
            const SizedBox(height: 16),
            ...options.map((t) {
              final (mode, label, icon) = t;
              final selected = themeProvider.themeMode == mode;
              return ListTile(
                leading: Icon(icon, color: selected ? p.info : p.textSecondary),
                title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? p.info : p.textPrimary)),
                trailing: selected ? Icon(PhosphorIconsFill.checkCircle, color: p.info) : null,
                onTap: () { themeProvider.setThemeMode(mode); Navigator.pop(context); },
                shape: AppShapes.border(radius: AppShapes.radiusMd),
                tileColor: selected ? p.infoSoft : Colors.transparent,
              );
            }),
          ],
        ),
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
      case ThemeMode.system:
        return l10n.themeSystem;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = context.watch<LanguageProvider>().languageCode;
    final langLabel = langCode == 'fr' ? 'Français' : langCode == 'ar' ? 'العربية' : 'English';
    final auth = context.watch<AuthProvider>();
    final reports = context.watch<ReportsProvider>();
    final themeMode = context.watch<ThemeProvider>().themeMode;
    final p = AppPalette.of(context);

    final user = auth.user;
    final totalReports = reports.total;
    final resolvedCount = reports.reports.where((r) => r.isResolved).length;
    final activeCount = reports.reports.where((r) => r.isActive).length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            title: Text(l10n.profile),
            leading: IconButton(
              icon: Icon(PhosphorIconsRegular.arrowLeft),
              onPressed: () => context.go(AppRoutes.home),
            ),
            actions: [
              TourButton(onPressed: () => _showTour(l10n)),
              IconButton(icon: Icon(PhosphorIconsRegular.gearSix), onPressed: _scrollToSettings),
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
                    decoration: AppShapes.card(color: p.surface, radius: AppShapes.radiusLg, borderColor: p.divider),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: AppShapes.card(color: p.infoSoft, radius: AppShapes.radiusPill),
                              child: Icon(PhosphorIconsDuotone.userCircle, color: p.info, size: 40),
                            ),
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                width: 26, height: 26,
                                decoration: AppShapes.card(color: p.ink, radius: AppShapes.radiusPill),
                                child: const Icon(PhosphorIconsBold.pencilSimple, color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          user?.fullName ?? 'Guest',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        if (user?.phone != null)
                          Text(user!.phone!, style: TextStyle(fontSize: 13, color: p.textSecondary))
                        else if (user?.email != null)
                          Text(user!.email!, style: TextStyle(fontSize: 13, color: p.textSecondary)),
                        if (user != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: AppShapes.card(color: p.infoSoft, radius: AppShapes.radiusPill),
                            child: Text(
                              user.role == 'citizen' ? 'Citizen' : user.role,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.info),
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
                      _StatCard(value: '$totalReports', label: l10n.myReports, icon: PhosphorIconsRegular.flag, color: p.ink),
                      const SizedBox(width: 12),
                      _StatCard(value: '$resolvedCount', label: l10n.resolvedLabel, icon: PhosphorIconsRegular.checkCircle, color: p.safe),
                      const SizedBox(width: 12),
                      _StatCard(value: '$activeCount', label: l10n.activeLabel, icon: PhosphorIconsRegular.clock, color: p.info),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent activity
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(l10n.recentActivitySection, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.textPrimary)),
                  ),
                  const SizedBox(height: 12),

                  ...reports.reports.take(3).toList().asMap().entries.map((entry) {
                    final r = entry.value;
                    final cat = reports.categoryById(r.categoryId);
                    final slug = cat?.slug ?? 'infrastructure';
                    return _ActivityRow(
                      icon: categoryIconData(cat?.icon),
                      color: categoryColorBySlug(slug),
                      title: r.title,
                      status: ReportStatusX.fromApi(r.status),
                      date: DateFormat('d MMM y').format(r.createdAt.toLocal()),
                      index: entry.key,
                    );
                  }),

                  if (reports.reports.isEmpty && !reports.loading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('No reports yet.', style: TextStyle(color: p.textHint, fontSize: 13)),
                    ),

                  TextButton(
                    onPressed: () => context.go(AppRoutes.myReports),
                    child: Text(l10n.viewAllReports),
                  ),

                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),

                  Column(
                    key: _settingsKey,
                    children: [
                      _SettingsTile(
                        icon: PhosphorIconsRegular.bell,
                        label: l10n.notifications,
                        onTap: () => context.push(AppRoutes.notificationSettings),
                      ),
                      _SettingsTile(
                        icon: PhosphorIconsRegular.translate,
                        label: l10n.language,
                        trailing: langLabel,
                        onTap: () => _showLanguagePicker(context, l10n),
                      ),
                      _SettingsTile(
                        icon: PhosphorIconsRegular.circleHalf,
                        label: l10n.theme,
                        trailing: _themeModeLabel(themeMode, l10n),
                        onTap: () => _showThemePicker(context, l10n),
                      ),
                      _SettingsTile(
                        icon: PhosphorIconsRegular.shieldCheck,
                        label: l10n.privacyPolicy,
                        onTap: () => context.push(AppRoutes.privacyPolicy),
                      ),
                      _SettingsTile(
                        icon: PhosphorIconsRegular.question,
                        label: l10n.helpSupport,
                        onTap: () => context.push(AppRoutes.helpSupport),
                      ),
                      _SettingsTile(
                        icon: PhosphorIconsRegular.signOut,
                        label: l10n.signOut,
                        textColor: p.urgent,
                        onTap: () async {
                          await context.read<AuthProvider>().logout();
                          if (context.mounted) context.go(AppRoutes.login);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const SahaliHeaderLogo(height: 24),
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
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: AppShapes.card(color: p.surface, radius: AppShapes.radiusMd, borderColor: p.divider),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: p.textHint)),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.icon, required this.color, required this.title, required this.status, required this.date, this.index = 0});
  final IconData icon;
  final Color color;
  final String title, date;
  final ReportStatus status;
  final int index;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: AppShapes.card(color: p.surface, radius: AppShapes.radiusMd, borderColor: p.divider),
    child: Row(
      children: [
        Container(
          width: 34, height: 34,
          decoration: AppShapes.card(color: color.withValues(alpha: 0.12), radius: AppShapes.radiusSm),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(date, style: TextStyle(fontSize: 11, color: p.textHint)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        StatusBadge(status: status),
      ],
    ),
  ).animate().fadeIn(duration: 260.ms, delay: (40 * index).ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
  }
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
    final p = AppPalette.of(context);
    final color = textColor ?? p.textPrimary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      trailing: trailing != null
          ? Text(trailing!, style: TextStyle(fontSize: 13, color: p.textHint))
          : Icon(PhosphorIconsRegular.caretRight, color: p.textHint),
      onTap: onTap,
    );
  }
}
