import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _page = 0;

  late final AnimationController _contentCtrl;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _heroScale;

  @override
  void initState() {
    super.initState();
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
    _contentFade = CurvedAnimation(
      parent: _contentCtrl,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentCtrl,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    ));
    _heroScale = Tween<double>(begin: 0.50, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0, 0.85, curve: Curves.elasticOut),
      ),
    );
    _contentCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int p) {
    setState(() => _page = p);
    _contentCtrl
      ..reset()
      ..forward();
  }

  void _next() {
    if (_page < 2) {
      _pageCtrl.animateToPage(
        _page + 1,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go(AppRoutes.language);
    }
  }

  void _skip() => context.go(AppRoutes.language);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final slides = [
      _Slide(
        icon: Icons.campaign_rounded,
        gradientColors: const [Color(0xFF2563EB), Color(0xFF1E3A8A)],
        accentColor: const Color(0xFF93C5FD),
        title: l.ob1Title,
        sub: l.ob1Sub,
      ),
      _Slide(
        icon: Icons.query_stats_rounded,
        gradientColors: const [Color(0xFF7C3AED), Color(0xFF4C1D95)],
        accentColor: const Color(0xFFC4B5FD),
        title: l.ob2Title,
        sub: l.ob2Sub,
      ),
      _Slide(
        icon: Icons.handshake_rounded,
        gradientColors: const [Color(0xFF0D9488), Color(0xFF064E3B)],
        accentColor: const Color(0xFF6EE7B7),
        title: l.ob3Title,
        sub: l.ob3Sub,
      ),
    ];

    final slide = slides[_page];

    return Scaffold(
      body: Stack(
        children: [
          // ── Animated gradient background ───────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: slide.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            width: double.infinity,
            height: double.infinity,
          ),

          // ── Decorative circles ─────────────────────────────────────────
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -90,
            child: Container(
              width: 330,
              height: 330,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            right: -50,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: TextButton(
                      onPressed: _skip,
                      style: TextButton.styleFrom(
                        foregroundColor:
                            Colors.white.withValues(alpha: 0.75),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      child: Text(
                        l.onboardingSkip,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),

                // PageView with animated content
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: _onPageChanged,
                    itemCount: slides.length,
                    itemBuilder: (_, i) => _PageContent(
                      slide: slides[i],
                      contentFade: _contentFade,
                      contentSlide: _contentSlide,
                      heroScale: _heroScale,
                      isActive: i == _page,
                    ),
                  ),
                ),

                // ── Bottom controls ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 44),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Animated page dots
                      Row(
                        children: List.generate(slides.length, (i) {
                          final active = i == _page;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.only(right: 7),
                            width: active ? 24.0 : 8.0,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(100),
                            ),
                          );
                        }),
                      ),

                      // Next / Commencer button
                      GestureDetector(
                        onTap: _next,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          padding: EdgeInsets.symmetric(
                            horizontal: _page == 2 ? 28 : 22,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: Text(
                                  _page == 2
                                      ? l.onboardingStart
                                      : l.onboardingNext,
                                  key: ValueKey(_page == 2),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: slide.gradientColors.first,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                _page == 2
                                    ? Icons.rocket_launch_rounded
                                    : Icons.arrow_forward_rounded,
                                color: slide.gradientColors.first,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slide data ───────────────────────────────────────────────────────────────

class _Slide {
  const _Slide({
    required this.icon,
    required this.gradientColors,
    required this.accentColor,
    required this.title,
    required this.sub,
  });
  final IconData icon;
  final List<Color> gradientColors;
  final Color accentColor;
  final String title, sub;
}

// ─── Animated page content ────────────────────────────────────────────────────

class _PageContent extends StatelessWidget {
  const _PageContent({
    required this.slide,
    required this.contentFade,
    required this.contentSlide,
    required this.heroScale,
    required this.isActive,
  });

  final _Slide slide;
  final Animation<double> contentFade;
  final Animation<Offset> contentSlide;
  final Animation<double> heroScale;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: FadeTransition(
        opacity: isActive ? contentFade : const AlwaysStoppedAnimation(1.0),
        child: SlideTransition(
          position: isActive
              ? contentSlide
              : const AlwaysStoppedAnimation(Offset.zero),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hero icon in a glowing circle
              ScaleTransition(
                scale: isActive
                    ? heroScale
                    : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  width: 164,
                  height: 164,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 48,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Icon(slide.icon, color: Colors.white, size: 74),
                ),
              ),

              const SizedBox(height: 52),

              // Title
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 18),

              // Subtitle
              Text(
                slide.sub,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.80),
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
