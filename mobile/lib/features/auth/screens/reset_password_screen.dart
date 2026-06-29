import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';
import '_auth_widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String identifier; // "email|||debugCode" or just "email"

  const ResetPasswordScreen({super.key, required this.identifier});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _success = false;
  String? _localError;

  late final String _identifier;
  String? _debugCode;

  @override
  void initState() {
    super.initState();
    final parts = widget.identifier.split('|||');
    _identifier = parts[0];
    if (parts.length > 1) _debugCode = parts[1];
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context);

    if (_success) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, size: 72, color: AppColors.success),
                const SizedBox(height: 24),
                Text(l10n.passwordResetSuccess,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 32),
                AuthPrimaryButton(
                  label: l10n.backToLogin,
                  loading: false,
                  onPressed: () => context.go(AppRoutes.login),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthHeader(
                title: l10n.resetPasswordTitle,
                subtitle: l10n.resetPasswordSub,
              ),
              const SizedBox(height: 8),
              // Show identifier
              Text(_identifier,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
              const SizedBox(height: 24),

              // Dev code hint
              if (_debugCode != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warningContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.bug_report_outlined, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text('${l10n.devCodeHint} $_debugCode',
                        style: const TextStyle(fontSize: 13, color: AppColors.warning, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              // Code input
              TextField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 10,
                ),
                decoration: InputDecoration(
                  labelText: l10n.resetCode,
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),

              // New password
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.newPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm password
              TextField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(context),
                decoration: InputDecoration(
                  labelText: l10n.confirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              AuthErrorBanner(error: _localError ?? auth.error),
              const SizedBox(height: 8),

              AuthPrimaryButton(
                label: l10n.resetPasswordBtn,
                loading: auth.loading,
                onPressed: () => _submit(context),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthProvider>();
    auth.clearError();
    setState(() => _localError = null);

    final code = _codeCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (code.length < 6) return;
    if (pass.length < 8) {
      setState(() => _localError = l10n.passwordTooShort);
      return;
    }
    if (pass != confirm) {
      setState(() => _localError = l10n.passwordsDoNotMatch);
      return;
    }

    final ok = await auth.resetPassword(_identifier, code, pass);
    if (ok && mounted) setState(() => _success = true);
  }
}
