import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../shared/widgets/sahali_header_logo.dart';
import '../../../core/l10n/app_localizations.dart';

/// Logo + title + subtitle header used on every auth screen
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SahaliHeaderLogo(height: 32),
        const SizedBox(height: 28),
        Text(title, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(fontSize: 14, color: p.textSecondary)),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }
}

/// Red error banner — only shown when error != null
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.error});
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (error == null || error!.isEmpty) return const SizedBox.shrink();
    final p = AppPalette.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppShapes.card(color: p.urgentSoft, radius: AppShapes.radiusMd),
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.warningCircle, size: 18, color: p.urgent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(error!, style: TextStyle(fontSize: 13, color: p.urgent)),
          ),
        ],
      ),
    ).animate().shake(duration: 320.ms, hz: 4);
  }
}

/// Dev-only OTP/verification code hint — shown on phone OTP, email verify,
/// and password reset screens when the backend returns a debug code.
class AuthDebugCodeHint extends StatelessWidget {
  const AuthDebugCodeHint({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: AppShapes.card(color: p.warningContainer, radius: AppShapes.radiusSm),
      child: Row(children: [
        Icon(PhosphorIconsRegular.bugBeetle, size: 16, color: p.warning),
        const SizedBox(width: 8),
        Text('${l10n.devCodeHint} $code',
            style: TextStyle(fontSize: 13, color: p.warning, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Full-width primary button
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Full-width outlined secondary button with icon
class AuthOutlinedButton extends StatelessWidget {
  const AuthOutlinedButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: p.border, width: 1.5),
          foregroundColor: p.textPrimary,
          shape: AppShapes.pill(),
        ),
      ),
    );
  }
}

/// "— or —" divider
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});
  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      children: [
        Expanded(child: Divider(color: p.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('ou', style: TextStyle(fontSize: 12, color: p.textHint)),
        ),
        Expanded(child: Divider(color: p.divider)),
      ],
    );
  }
}

/// Bottom "Already have account? Sign in" row
class AuthBottomLink extends StatelessWidget {
  const AuthBottomLink({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.onTap,
  });
  final String question;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (question.isNotEmpty) ...[
            Text(question, style: TextStyle(fontSize: 14, color: p.textSecondary)),
            const SizedBox(width: 4),
          ],
          GestureDetector(
            onTap: onTap,
            child: Text(actionLabel,
                style: TextStyle(
                    fontSize: 14,
                    color: p.ink,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
