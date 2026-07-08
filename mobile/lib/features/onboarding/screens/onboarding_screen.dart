import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../shared/widgets/sa_animated_background.dart';

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
    final p = AppPalette.of(context);

    final slides = [
      _Slide(icon: PhosphorIconsDuotone.megaphoneSimple, title: l.ob1Title, sub: l.ob1Sub),
      _Slide(icon: PhosphorIconsDuotone.mapTrifold, title: l.ob2Title, sub: l.ob2Sub),
      _Slide(icon: PhosphorIconsDuotone.handHeart, title: l.ob3Title, sub: l.ob3Sub),
    ];

    return SaAnimatedBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
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
                    foregroundColor: p.inkSoft,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(
                    l.onboardingSkip,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
                          color: active ? p.ink : p.ink.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      );
                    }),
                  ),

                  // Next / Commencer pill button
                  GestureDetector(
                    onTap: _next,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.symmetric(
                        horizontal: _page == 2 ? 28 : 22,
                        vertical: 16,
                      ),
                      decoration: AppShapes.card(
                        color: p.ink,
                        radius: AppShapes.radiusPill,
                        shadows: [
                          BoxShadow(
                            color: p.ink.withValues(alpha: 0.28),
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
                              _page == 2 ? l.onboardingStart : l.onboardingNext,
                              key: ValueKey(_page == 2),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: p.background,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _page == 2 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                            color: p.background,
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
      ),
    );
  }
}

// ─── Slide data ───────────────────────────────────────────────────────────────

class _Slide {
  const _Slide({required this.icon, required this.title, required this.sub});
  final IconData icon;
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
    final p = AppPalette.of(context);
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
              // Hero icon in a frosted squircle
              ScaleTransition(
                scale: isActive
                    ? heroScale
                    : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: AppShapes.card(
                    color: Colors.white.withValues(alpha: 0.55),
                    radius: AppShapes.radiusXl,
                    borderColor: Colors.white.withValues(alpha: 0.6),
                    borderWidth: 1.5,
                    shadows: [
                      BoxShadow(
                        color: p.ink.withValues(alpha: 0.10),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: PhosphorIcon(slide.icon, color: p.ink, duotoneSecondaryColor: Colors.white, size: 68),
                ),
              ),

              const SizedBox(height: 44),

              // Title
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 14),

              // Subtitle
              Text(
                slide.sub,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: p.inkSoft,
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
