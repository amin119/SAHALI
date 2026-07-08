import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/notifications/providers/notifications_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../shared/widgets/sahali_header_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  // Continuous sonar-pulse for the FAB
  late final AnimationController _pulseCtrl;
  // Press-scale bounce
  late final AnimationController _pressCtrl;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) {
        context.read<NotificationsProvider>().load();
        LocalNotificationService.instance.requestPermissionIfNeeded();
      }
    });
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.87).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onFabDown(TapDownDetails _) => _pressCtrl.forward();
  void _onFabUp(TapUpDetails _) {
    _pressCtrl.reverse();
    context.go(AppRoutes.reportCategory);
  }
  void _onFabCancel() => _pressCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: _appBar(context, l10n),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // ── Community / Tunisia stats ───────────────────────────────
            _CommunityCard(l10n: l10n),
            // ── Offline queue banner ────────────────────────────────────
            _QueueBanner(l10n: l10n),
            const SizedBox(height: 36),
            // ── Centered pulsing FAB ────────────────────────────────────
            _CenteredFab(
              l10n: l10n,
              pulseCtrl: _pulseCtrl,
              pressScale: _pressScale,
              onTapDown: _onFabDown,
              onTapUp: _onFabUp,
              onTapCancel: _onFabCancel,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(
      BuildContext context, AppLocalizations l10n) {
    final unread = context.watch<NotificationsProvider>().unreadCount;
    final p = AppPalette.of(context);
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      title: const SahaliHeaderLogo(height: 32),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: AppShapes.card(color: Colors.white.withValues(alpha: 0.55), radius: AppShapes.radiusMd),
              child: IconButton(
                icon: PhosphorIcon(PhosphorIconsDuotone.bell, color: p.ink),
                onPressed: () => context.go(AppRoutes.notifications),
              ),
            ),
            if (unread > 0)
              Positioned(
                top: 6,
                right: 14,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: p.urgent, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tunisia Community Card — fetches real stats from /admin/stats/public
// ═══════════════════════════════════════════════════════════════════════════════

class _CommunityCard extends StatefulWidget {
  const _CommunityCard({required this.l10n});
  final AppLocalizations l10n;

  @override
  State<_CommunityCard> createState() => _CommunityCardState();
}

class _CommunityCardState extends State<_CommunityCard> {
  int _total = 0;
  int _resolved = 0;
  int _active = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final res = await ApiClient.instance.dio.get('/admin/stats/public');
      final d = res.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _total    = (d['total']    as num?)?.toInt() ?? 0;
          _resolved = (d['resolved'] as num?)?.toInt() ?? 0;
          _active   = (d['active']   as num?)?.toInt() ?? 0;
          _loaded   = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  String _fmt(int n) {
    if (n >= 1000) {
      final s = n.toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
        buf.write(s[i]);
      }
      return buf.toString();
    }
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final p = AppPalette.of(context);
    final resolvedPct = _total > 0 ? _resolved / _total : 0.0;
    final resolvedPctStr = _total > 0 ? ' (${(_resolved * 100 ~/ _total)}%)' : '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppShapes.card(
        color: p.surface,
        radius: AppShapes.radiusXl,
        borderColor: p.divider,
        shadows: [
          BoxShadow(
            color: p.ink.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: AppShapes.card(color: p.infoSoft, radius: AppShapes.radiusSm),
                child: PhosphorIcon(PhosphorIconsDuotone.chartLineUp, color: p.info, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.communityTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: p.ink,
                      ),
                    ),
                    Text(
                      l10n.communitySub,
                      style: TextStyle(fontSize: 11, color: p.textHint),
                    ),
                  ],
                ),
              ),
              _LiveBadge(label: l10n.liveLabel),
            ],
          ),

          const SizedBox(height: 20),

          // ── Big number ──────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _loaded
                  ? Text(
                      _fmt(_total),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: p.ink,
                        height: 1.0,
                      ),
                    )
                  : const SizedBox(
                      width: 80, height: 40,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  l10n.reportsSuffix,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: p.inkSoft,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Progress bar ─────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: resolvedPct),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                backgroundColor: p.divider,
                valueColor: AlwaysStoppedAnimation(p.safe),
                minHeight: 6,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _StatPill(
                  color: p.safe,
                  softColor: p.safeSoft,
                  text: '${_fmt(_resolved)} ${l10n.resolvedLabel2}$resolvedPctStr',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatPill(
                  color: p.info,
                  softColor: p.infoSoft,
                  text: '${_fmt(_active)} ${l10n.activeLabel2}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Offline queue banner — shows when reports are waiting to sync
// ═══════════════════════════════════════════════════════════════════════════════

class _QueueBanner extends StatelessWidget {
  const _QueueBanner({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();
    final p = AppPalette.of(context);
    if (!sync.hasPending) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => sync.flush(),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: AppShapes.card(color: p.infoSoft, radius: AppShapes.radiusMd),
        child: Row(
          children: [
            PhosphorIcon(PhosphorIconsDuotone.cloudArrowUp, size: 18, color: p.info),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.pendingReportsBanner(sync.pendingCount),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.info),
              ),
            ),
            Text(
              l10n.syncNow,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: p.info,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge({required this.label});
  final String label;

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _blink;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _blink = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: AppShapes.card(color: p.urgentSoft, radius: AppShapes.radiusPill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _blink,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: p.urgent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: p.urgent,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.color, required this.softColor, required this.text});
  final Color color;
  final Color softColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: AppShapes.card(color: softColor, radius: AppShapes.radiusPill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Centered pulsing FAB
// ═══════════════════════════════════════════════════════════════════════════════

class _CenteredFab extends StatelessWidget {
  const _CenteredFab({
    required this.l10n,
    required this.pulseCtrl,
    required this.pressScale,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });
  final AppLocalizations l10n;
  final AnimationController pulseCtrl;
  final Animation<double> pressScale;
  final GestureTapDownCallback onTapDown;
  final GestureTapUpCallback onTapUp;
  final VoidCallback onTapCancel;

  static const _btnD = 96.0;
  static const _maxMul = 2.0;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      children: [
        Text(
          l10n.tapToReport,
          style: TextStyle(
            fontSize: 13,
            color: p.inkSoft,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        // The SizedBox must accommodate the largest ring
        SizedBox(
          width: _btnD * _maxMul,
          height: _btnD * _maxMul,
          child: AnimatedBuilder(
            animation: pulseCtrl,
            builder: (context, child) {
              final t = pulseCtrl.value;
              final r1 = t;
              final r2 = (t + 0.48) % 1.0;

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer sonar ring 2
                  _SonarRing(
                      diameter: _btnD * (1 + r2 * (_maxMul - 1)),
                      opacity: (1 - r2) * 0.14),
                  // Outer sonar ring 1
                  _SonarRing(
                      diameter: _btnD * (1 + r1 * (_maxMul - 1)),
                      opacity: (1 - r1) * 0.14),
                  // Glow halo (static)
                  _SonarRing(
                      diameter: _btnD + 26,
                      opacity: 0.12),
                  // Button (child keeps scale-transition alive)
                  child!,
                ],
              );
            },
            child: ScaleTransition(
              scale: pressScale,
              child: GestureDetector(
                onTapDown: onTapDown,
                onTapUp: onTapUp,
                onTapCancel: onTapCancel,
                child: Container(
                  width: _btnD,
                  height: _btnD,
                  decoration: AppShapes.card(
                    color: p.urgent,
                    radius: AppShapes.radiusXl,
                    shadows: [
                      BoxShadow(
                        color: p.urgent.withValues(alpha: 0.44),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.reportNow,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.reportNowSub,
          style: TextStyle(
              fontSize: 13, color: p.inkSoft),
        ),
      ],
    );
  }
}

class _SonarRing extends StatelessWidget {
  const _SonarRing({required this.diameter, required this.opacity});
  final double diameter;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: p.urgent.withValues(alpha: opacity),
      ),
    );
  }
}
