import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/sa_button.dart';
import '../viewmodels/report_form_provider.dart';

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({super.key});
  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  bool _copied = false;
  String _trackingCode = '';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 1.0));
    _ctrl.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    if (extra is String && extra.isNotEmpty) {
      _trackingCode = extra;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF22C55E).withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
                ),
              ),
              const SizedBox(height: 28),

              FadeTransition(
                opacity: _fade,
                child: Column(
                  children: [
                    Text(
                      l10n.reportSubmitted,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.reportSubmittedSub,
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    if (_trackingCode.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          children: [
                            Text(
                              l10n.trackingCodeLabel,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textHint, letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _trackingCode,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 2),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _copy,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _copied ? AppColors.success.withValues(alpha: 0.1) : AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _copied ? Icons.check_circle_rounded : Icons.copy_rounded,
                                      size: 15,
                                      color: _copied ? AppColors.success : AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _copied ? l10n.copied : l10n.copyCode,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _copied ? AppColors.success : AppColors.primary,
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
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _StepRow(icon: Icons.inbox_rounded, text: l10n.confirmStep1),
                          const SizedBox(height: 10),
                          _StepRow(icon: Icons.engineering_rounded, text: l10n.confirmStep2),
                          const SizedBox(height: 10),
                          _StepRow(icon: Icons.notifications_active_rounded, text: l10n.confirmStep3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              FadeTransition(
                opacity: _fade,
                child: Column(
                  children: [
                    SaButton(label: l10n.trackMyReport, onPressed: _goToMyReports),
                    const SizedBox(height: 12),
                    SaOutlinedButton(label: l10n.backToHome, onPressed: _goToHome),
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

class _StepRow extends StatelessWidget {
  const _StepRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4))),
      ],
    );
  }
}
