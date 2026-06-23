import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/sahali_logo.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _otpCtrl.dispose();
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Row(
                children: [
                  const SahaliLogo(size: 44),
                  const SizedBox(width: 12),
                  Text(
                    l10n.appNameAr,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                l10n.welcomeBack,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.loginSubtitle,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabs,
                  indicator: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textHint,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: [Tab(text: l10n.tabPhoneOtp), Tab(text: l10n.tabEmail)],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 240,
                child: TabBarView(
                  controller: _tabs,
                  children: [_otpTab(l10n), _emailTab(l10n)],
                ),
              ),
              if (auth.error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    auth.error!,
                    style: const TextStyle(fontSize: 13, color: AppColors.error),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: auth.loading ? null : () => _submit(context),
                  child: auth.loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.continueBtn),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: Text(l10n.skipForNow, style: const TextStyle(color: AppColors.textHint)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _otpTab(AppLocalizations l10n) {
    return Column(
      children: [
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: l10n.phoneNumber,
            prefixIcon: const Icon(Icons.phone_outlined),
            hintText: l10n.phoneHint,
          ),
        ),
        if (_otpSent) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 8),
            decoration: InputDecoration(
              labelText: l10n.enterOtp,
              counterText: '',
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (!_otpSent)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _sendOtp(context),
              child: Text(l10n.sendOtp),
            ),
          ),
      ],
    );
  }

  Widget _emailTab(AppLocalizations l10n) {
    return Column(
      children: [
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: l10n.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passCtrl,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: l10n.password,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendOtp(BuildContext context) async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    final auth = context.read<AuthProvider>();
    auth.clearError();
    try {
      await auth.requestOtp(phone);
      if (mounted) setState(() => _otpSent = true);
    } catch (_) {}
  }

  Future<void> _submit(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    auth.clearError();

    bool success;
    if (_tabs.index == 0) {
      if (!_otpSent) {
        await _sendOtp(context);
        return;
      }
      success = await auth.verifyOtp(
        _phoneCtrl.text.trim(),
        _otpCtrl.text.trim(),
      );
    } else {
      success = await auth.loginWithPassword(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
    }

    if (success && mounted) context.go(AppRoutes.home);
  }
}
