import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shapes.dart';
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
    final p = AppPalette.of(context);
    return Scaffold(
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
                  decoration: AppShapes.card(color: p.infoSoft, radius: AppShapes.radiusLg),
                  child: Icon(PhosphorIconsDuotone.envelopeSimpleOpen,
                      size: 36, color: p.info),
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
                AuthDebugCodeHint(code: _debugCode!),
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
                        style: TextStyle(fontSize: 13, color: p.textHint))
                    : TextButton(
                        onPressed: _sendCode,
                        child: Text(l10n.resendCode,
                            style: TextStyle(color: p.ink)),
                      ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: Text(l10n.skipVerification,
                      style: TextStyle(fontSize: 13, color: p.textHint)),
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
