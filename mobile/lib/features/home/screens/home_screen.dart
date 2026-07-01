import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/notifications/providers/notifications_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/sahali_logo.dart';

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
      backgroundColor: AppColors.background,
      appBar: _appBar(context, l10n),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // ── Community / Tunisia stats ───────────────────────────────
            _CommunityCard(l10n: l10n),
            const Spacer(),
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
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: const [
          SahaliLogo(size: 36),
          SizedBox(width: 10),
          Text(
            'سهلي',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: AppColors.textPrimary),
              onPressed: () => context.go(AppRoutes.notifications),
            ),
            if (unread > 0)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
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
    final resolvedPct = _total > 0 ? _resolved / _total : 0.0;
    final resolvedPctStr = _total > 0 ? ' (${(_resolved * 100 ~/ _total)}%)' : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primaryContainer, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
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
              const Text('🇹🇳', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.communityTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      l10n.communitySub,
                      style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
              _LiveBadge(label: l10n.liveLabel),
            ],
          ),

          const SizedBox(height: 18),

          // ── Big number ──────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _loaded
                  ? Text(
                      _fmt(_total),
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        height: 1.0,
                      ),
                    )
                  : const SizedBox(
                      width: 80, height: 44,
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Progress bar ─────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: resolvedPct,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.success),
              minHeight: 8,
            ),
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              _DotLabel(
                color: AppColors.success,
                text: '${_fmt(_resolved)} ${l10n.resolvedLabel2}$resolvedPctStr',
              ),
              const Spacer(),
              _DotLabel(
                color: AppColors.statusInProgress,
                text: '${_fmt(_active)} ${l10n.activeLabel2}',
              ),
            ],
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.successContainer,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _blink,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _DotLabel extends StatelessWidget {
  const _DotLabel({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
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

  static const _btnD = 100.0;
  static const _maxMul = 2.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          l10n.tapToReport,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textHint,
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
                      opacity: (1 - r2) * 0.12),
                  // Outer sonar ring 1
                  _SonarRing(
                      diameter: _btnD * (1 + r1 * (_maxMul - 1)),
                      opacity: (1 - r1) * 0.12),
                  // Glow halo (static)
                  _SonarRing(
                      diameter: _btnD + 26,
                      opacity: 0.10),
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
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2B6CE6), AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.44),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.reportNow,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.reportNowSub,
          style: const TextStyle(
              fontSize: 13, color: AppColors.textSecondary),
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
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: opacity),
      ),
    );
  }
}

