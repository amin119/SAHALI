import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/network/api_client.dart';
import '../../../data/services/report_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/step_bar.dart';
import '../../../shared/widgets/sa_button.dart';
import '../viewmodels/report_form_provider.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    final form = context.read<ReportFormProvider>();
    if (form.categoryId == null) {
      setState(() => _error = 'Please select a category first.');
      return;
    }

    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      final signedIn = await _showSignInSheet();
      if (!signedIn) return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final title = form.categoryLabel ?? 'Report';
      final report = await ReportService().submitReport(
        categoryId: form.categoryId!,
        title: title,
        description: form.description.isNotEmpty ? form.description : null,
        lat: form.location.latitude,
        lng: form.location.longitude,
      );
      if (mounted) {
        context.go(AppRoutes.reportConfirmation, extra: report.trackingCode);
      }
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = dioMessage(e);
      });
    }
  }

  Future<bool> _showSignInSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SignInSheet(),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final form = context.watch<ReportFormProvider>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.newReport),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.reportDescription),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: StepBar(step: 5, total: 6),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reviewReport,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.reviewReportHint,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            _SectionCard(
              label: l10n.reviewCategory,
              editLabel: l10n.edit,
              onEdit: () => context.go(AppRoutes.reportCategory),
              child: form.categoryLabel != null
                  ? Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: form.categoryColor!.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(form.categoryIcon, color: form.categoryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(form.categoryLabel!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      ],
                    )
                  : Text(l10n.noCategory, style: const TextStyle(fontSize: 14, color: AppColors.textHint)),
            ),
            const SizedBox(height: 12),

            _SectionCard(
              label: l10n.reviewPhoto,
              editLabel: l10n.edit,
              onEdit: () => context.go(AppRoutes.reportPhoto),
              child: form.photo != null
                  ? Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(form.photo!, width: 64, height: 64, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        Text(l10n.photoAttached, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      ],
                    )
                  : Text(l10n.noPhoto, style: const TextStyle(fontSize: 14, color: AppColors.textHint)),
            ),
            const SizedBox(height: 12),

            _SectionCard(
              label: l10n.reviewLocation,
              editLabel: l10n.edit,
              onEdit: () => context.go(AppRoutes.reportLocation),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${form.location.latitude.toStringAsFixed(5)}, ${form.location.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            _SectionCard(
              label: l10n.reviewDescription,
              editLabel: l10n.edit,
              onEdit: () => context.go(AppRoutes.reportDescription),
              child: form.description.isNotEmpty
                  ? Text(form.description, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5))
                  : Text(l10n.noDescription, style: const TextStyle(fontSize: 14, color: AppColors.textHint)),
            ),
            const SizedBox(height: 28),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.textHint, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.submitDisclaimer,
                      style: const TextStyle(fontSize: 12, color: AppColors.textHint, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.error)),
              ),
            ],

            const SizedBox(height: 20),
            SaButton(
              label: l10n.submitReport,
              isLoading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compact sign-in sheet shown when a guest tries to submit ────────────────

class _SignInSheet extends StatefulWidget {
  @override
  State<_SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends State<_SignInSheet> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
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
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context);
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.signInToSubmit, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(l10n.signInReadySub, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabs,
              indicator: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textHint,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: [Tab(text: l10n.tabEmail), Tab(text: l10n.tabPhoneOtp)],
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: _otpSent ? 180 : 140,
            child: TabBarView(
              controller: _tabs,
              children: [
                // Email tab
                Column(
                  children: [
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: l10n.tabEmail, prefixIcon: const Icon(Icons.email_outlined), isDense: true),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        isDense: true,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                  ],
                ),
                // Phone/OTP tab
                Column(
                  children: [
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(labelText: l10n.phoneNumber, prefixIcon: const Icon(Icons.phone_outlined), hintText: l10n.phoneHint, isDense: true),
                    ),
                    if (_otpSent) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _otpCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 8),
                        decoration: InputDecoration(labelText: l10n.enterOtp, counterText: '', isDense: true),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _sendOtp(context),
                          child: Text(l10n.sendOtp, style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          if (auth.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(auth.error!, style: const TextStyle(fontSize: 12, color: AppColors.error)),
            ),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: auth.loading ? null : () => _submit(context),
              child: auth.loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(l10n.signInAndSubmit),
            ),
          ),
        ],
      ),
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
      success = await auth.loginWithPassword(_emailCtrl.text.trim(), _passCtrl.text);
    } else {
      if (!_otpSent) { await _sendOtp(context); return; }
      success = await auth.verifyOtp(_phoneCtrl.text.trim(), _otpCtrl.text.trim());
    }
    if (success && mounted) Navigator.of(context).pop(true);
  }
}

// ── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.label, required this.editLabel, required this.child, required this.onEdit});
  final String label;
  final String editLabel;
  final Widget child;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textHint, letterSpacing: 0.8)),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: Text(editLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
