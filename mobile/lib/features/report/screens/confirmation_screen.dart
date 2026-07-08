import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/sa_button.dart';
import '../../../shared/widgets/sa_success_badge.dart';
import '../viewmodels/report_form_provider.dart';

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({super.key});
  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  bool _copied = false;
  String _trackingCode = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    if (extra is String && extra.isNotEmpty) {
      _trackingCode = extra;
    }
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _trackingCode));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _goToMyReports() {
    context.read<ReportFormProvider>().reset();
    context.go(AppRoutes.myReports);
  }

  void _goToHome() {
    context.read<ReportFormProvider>().reset();
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppPalette.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              const SaSuccessBadge(size: 100),
              const SizedBox(height: 28),

              Column(
                children: [
                  Text(
                    l10n.reportSubmitted,
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.reportSubmittedSub,
                    style: TextStyle(fontSize: 14, color: p.textSecondary, height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  if (_trackingCode.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppShapes.card(color: p.surface, radius: AppShapes.radiusXl, borderColor: p.divider),
                      child: Column(
                        children: [
                          Text(
                            l10n.trackingCodeLabel,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.textHint, letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _trackingCode,
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: p.ink, letterSpacing: 2),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _copy,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: AppShapes.card(
                                color: _copied ? p.safeSoft : p.surfaceVariant,
                                radius: AppShapes.radiusPill,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _copied ? PhosphorIconsRegular.checkCircle : PhosphorIconsRegular.copySimple,
                                    size: 15,
                                    color: _copied ? p.safe : p.ink,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _copied ? l10n.copied : l10n.copyCode,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _copied ? p.safe : p.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppShapes.card(color: p.surfaceVariant, radius: AppShapes.radiusLg),
                    child: Column(
                      children: [
                        _StepRow(icon: PhosphorIconsDuotone.tray, text: l10n.confirmStep1),
                        const SizedBox(height: 10),
                        _StepRow(icon: PhosphorIconsDuotone.wrench, text: l10n.confirmStep2),
                        const SizedBox(height: 10),
                        _StepRow(icon: PhosphorIconsDuotone.bellRinging, text: l10n.confirmStep3),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms, delay: 280.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),

              const Spacer(),

              Column(
                children: [
                  SaButton(label: l10n.trackMyReport, onPressed: _goToMyReports),
                  const SizedBox(height: 12),
                  SaOutlinedButton(label: l10n.backToHome, onPressed: _goToHome),
                ],
              ).animate().fadeIn(duration: 400.ms, delay: 280.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: p.ink),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.4))),
      ],
    );
  }
}
