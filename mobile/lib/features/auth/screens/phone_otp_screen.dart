import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';
import '_auth_widgets.dart';

class PhoneOtpScreen extends StatefulWidget {
  const PhoneOtpScreen({super.key});
  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  int _resendCountdown = 0;
  Timer? _timer;
  String? _debugCode;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
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
              AuthHeader(
                title: l10n.phoneOtpTitle,
                subtitle: _otpSent
                    ? '${l10n.otpSentTo} ${_phoneCtrl.text.trim()}'
                    : l10n.phoneOtpSub,
              ),
              const SizedBox(height: 32),

              if (!_otpSent) ...[
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: InputDecoration(
                    labelText: l10n.phoneNumber,
                    hintText: l10n.phoneHint,
                    prefixIcon: Icon(PhosphorIconsRegular.phone),
                  ),
                ),
                const SizedBox(height: 24),
                AuthErrorBanner(error: auth.error),
                const SizedBox(height: 8),
                AuthPrimaryButton(
                  label: l10n.sendOtp,
                  loading: auth.loading,
                  onPressed: () => _sendOtp(context),
                ),
              ] else ...[
                // OTP code input
                TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 12,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.enterOtp,
                    counterText: '',
                  ),
                ),
                if (_debugCode != null) ...[
                  const SizedBox(height: 8),
                  AuthDebugCodeHint(code: _debugCode!),
                ],
                const SizedBox(height: 24),
                AuthErrorBanner(error: auth.error),
                const SizedBox(height: 8),
                AuthPrimaryButton(
                  label: l10n.verifyOtpBtn,
                  loading: auth.loading,
                  onPressed: () => _verify(context),
                ),
                const SizedBox(height: 16),
                Center(
                  child: _resendCountdown > 0
                      ? Text(l10n.resendCodeIn(_resendCountdown),
                          style: TextStyle(fontSize: 13, color: p.textHint))
                      : TextButton(
                          onPressed: () => _sendOtp(context),
                          child: Text(l10n.resendCode,
                              style: TextStyle(color: p.ink)),
                        ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendOtp(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    try {
      await auth.requestOtp(phone);
      if (mounted) {
        setState(() {
          _otpSent = true;
          _debugCode = null;
        });
        _startCountdown();
      }
    } catch (_) {}
  }

  Future<void> _verify(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final ok = await auth.verifyOtp(
      _phoneCtrl.text.trim(),
      _otpCtrl.text.trim(),
    );
    if (ok && mounted) context.go(AppRoutes.home);
  }
}
