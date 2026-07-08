import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';
import '_auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context);
    final p = AppPalette.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              AuthHeader(title: l10n.welcomeBack, subtitle: l10n.loginSubtitle),
              const SizedBox(height: 32),

              // Email field
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  labelText: l10n.emailAddress,
                  prefixIcon: Icon(PhosphorIconsRegular.envelopeSimple),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(context),
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: l10n.password,
                  prefixIcon: Icon(PhosphorIconsRegular.lockSimple),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? PhosphorIconsRegular.eye : PhosphorIconsRegular.eyeClosed),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.forgotPassword),
                  child: Text(l10n.forgotPassword,
                      style: TextStyle(fontSize: 13, color: p.ink)),
                ),
              ),
              const SizedBox(height: 4),

              AuthErrorBanner(error: auth.error),

              const SizedBox(height: 16),

              // Sign in button
              AuthPrimaryButton(
                label: l10n.continueBtn,
                loading: auth.loading,
                onPressed: () => _submit(context),
              ),
              const SizedBox(height: 16),

              // Divider
              const AuthDivider(),
              const SizedBox(height: 16),

              // Phone OTP
              AuthOutlinedButton(
                icon: PhosphorIconsRegular.phone,
                label: l10n.loginWithPhone,
                onPressed: () => context.push(AppRoutes.phoneOtp),
              ),
              const SizedBox(height: 32),

              // Register link
              AuthBottomLink(
                question: l10n.dontHaveAccount,
                actionLabel: l10n.signUpInstead,
                onTap: () => context.push(AppRoutes.register),
              ),

              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: Text(l10n.skipForNow,
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

  Future<void> _submit(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) return;
    final ok = await auth.loginWithPassword(email, pass);
    if (ok && mounted) context.go(AppRoutes.home);
  }
}
