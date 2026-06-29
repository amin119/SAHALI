import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/sahali_logo.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
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
                  prefixIcon: const Icon(Icons.email_outlined),
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
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
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
                      style: const TextStyle(fontSize: 13, color: AppColors.primary)),
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
                icon: Icons.phone_outlined,
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
