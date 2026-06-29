import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';
import '_auth_widgets.dart';

class EmailVerifyScreen extends StatefulWidget {
  final String email;
  const EmailVerifyScreen({super.key, required this.email});
  @override
  State<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends State<EmailVerifyScreen> {
  final _codeCtrl = TextEditingController();
  int _resendCountdown = 60;
  Timer? _timer;
  String? _debugCode;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown <= 0) {
        t.cancel();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  Future<void> _sendCode() async {
    final auth = context.read<AuthProvider>();
    final code = await auth.sendEmailVerification(widget.email);
    if (mounted) {
      setState(() => _debugCode = code);
      _startCountdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mark_email_read_outlined,
                      size: 36, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              AuthHeader(
                title: l10n.verifyEmailTitle,
                subtitle: '${l10n.verifyEmailSub}\n${widget.email}',
              ),
              const SizedBox(height: 32),

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
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 12,
                ),
                decoration: InputDecoration(
                  labelText: l10n.verificationCode,
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),

              AuthErrorBanner(error: auth.error),
              const SizedBox(height: 8),

              AuthPrimaryButton(
                label: l10n.verifyBtn,
                loading: auth.loading,
                onPressed: () => _verify(context),
              ),
              const SizedBox(height: 16),

              // Resend
              Center(
                child: _resendCountdown > 0
                    ? Text(l10n.resendCodeIn(_resendCountdown),
                        style: const TextStyle(fontSize: 13, color: AppColors.textHint))
                    : TextButton(
                        onPressed: _sendCode,
                        child: Text(l10n.resendCode,
                            style: const TextStyle(color: AppColors.primary)),
                      ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: Text(l10n.skipVerification,
                      style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verify(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final ok = await auth.confirmEmailVerification(
      widget.email,
      _codeCtrl.text.trim(),
    );
    if (ok && mounted) context.go(AppRoutes.home);
  }
}
