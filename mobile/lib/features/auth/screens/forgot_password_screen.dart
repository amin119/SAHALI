import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';
import '_auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
              AuthHeader(
                title: l10n.forgotPasswordTitle,
                subtitle: l10n.forgotPasswordSub,
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _send(context),
                decoration: InputDecoration(
                  labelText: l10n.emailOrPhone,
                  prefixIcon: const Icon(Icons.alternate_email_outlined),
                ),
              ),
              const SizedBox(height: 24),

              AuthErrorBanner(error: auth.error),
              const SizedBox(height: 8),

              AuthPrimaryButton(
                label: l10n.sendResetCode,
                loading: auth.loading,
                onPressed: () => _send(context),
              ),
              const SizedBox(height: 32),

              AuthBottomLink(
                question: '',
                actionLabel: l10n.backToLogin,
                onTap: () => context.pop(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final identifier = _ctrl.text.trim();
    if (identifier.isEmpty) return;

    // forgotPassword always succeeds from the user's perspective
    // debug_code returned only in dev mode
    final debugCode = await auth.forgotPassword(identifier);
    if (!mounted) return;

    // Pass identifier and optional debug code to reset screen
    final extra = debugCode != null ? '$identifier|||$debugCode' : identifier;
    context.push(AppRoutes.resetPassword, extra: extra);
  }
}
