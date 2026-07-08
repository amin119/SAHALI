import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/router/app_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/sync_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/step_bar.dart';
import '../../../shared/widgets/sa_button.dart';
import '../../../shared/widgets/sa_bottom_sheet.dart';
import '../viewmodels/report_form_provider.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _submitting = false;
  bool _uploadingPhoto = false;
  String? _error;

  Future<void> _submit() async {
    final form = context.read<ReportFormProvider>();
    final l10n = AppLocalizations.of(context);
    if (form.categoryId == null) {
      setState(() => _error = l10n.selectCategoryFirst);
      return;
    }

    final isLoggedIn = context.read<AuthProvider>().isLoggedIn;

    setState(() { _submitting = true; _error = null; });

    try {
      String? photoUrl;
      String? thumbnailUrl;
      final List<String> uploadedUrls = [];

      if (form.photos.isNotEmpty) {
        setState(() => _uploadingPhoto = true);
        for (final file in form.photos) {
          try {
            final filename = file.path.split(Platform.pathSeparator).last;
            final ext = filename.split('.').last.toLowerCase();
            final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
            final formData = FormData.fromMap({
              'file': await MultipartFile.fromFile(
                file.path,
                filename: filename,
                contentType: DioMediaType.parse(contentType),
              ),
            });
            final res = await ApiClient.instance.dio.post(
              '/reports/photo',
              data: formData,
              options: Options(sendTimeout: const Duration(seconds: 60)),
            );
            uploadedUrls.add(res.data['photo_url'] as String);
          } catch (_) {
            // Storage not configured on Render — skip photo
          }
        }
        if (uploadedUrls.isNotEmpty) {
          photoUrl = uploadedUrls.first;
          thumbnailUrl = uploadedUrls.first;
        }
        setState(() => _uploadingPhoto = false);
      }

      final payload = <String, dynamic>{
        'category_id': form.categoryId!,
        'title': form.categoryLabel ?? 'Report',
        if (form.description.isNotEmpty) 'description': form.description,
        'lat': form.location.latitude,
        'lng': form.location.longitude,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        'photo_urls': uploadedUrls,
      };

      try {
        final endpoint = isLoggedIn ? '/reports' : '/reports/anonymous';
        final res = await ApiClient.instance.dio.post(endpoint, data: payload);
        final trackingCode = res.data['tracking_code'] as String;
        if (mounted) context.go(AppRoutes.reportConfirmation, extra: trackingCode);
      } on DioException catch (e) {
        if (_isOffline(e)) {
          await SyncService.instance.enqueue(payload);
          if (mounted) {
            setState(() => _submitting = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(l10n.reportQueued),
              duration: const Duration(seconds: 4),
            ));
            context.go(AppRoutes.home);
          }
          return;
        }
        rethrow;
      }
    } catch (e) {
      setState(() {
        _submitting = false;
        _uploadingPhoto = false;
        _error = dioMessage(e);
      });
    }
  }

  static bool _isOffline(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout;

  Future<bool> _showSignInSheet() async {
    final result = await showSaBottomSheet<bool>(
      context,
      builder: (_) => _SignInSheet(),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final form = context.watch<ReportFormProvider>();
    final l10n = AppLocalizations.of(context);
    final p = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.newReport),
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft),
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
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.reviewReportHint,
              style: TextStyle(fontSize: 14, color: p.textSecondary),
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
                          decoration: AppShapes.card(color: form.categoryColor!.withValues(alpha: 0.12), radius: AppShapes.radiusSm),
                          child: Icon(form.categoryIcon, color: form.categoryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(form.categoryLabel!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.textPrimary)),
                      ],
                    )
                  : Text(l10n.noCategory, style: TextStyle(fontSize: 14, color: p.textHint)),
            ),
            const SizedBox(height: 12),

            _SectionCard(
              label: l10n.reviewPhoto,
              editLabel: l10n.edit,
              onEdit: () => context.go(AppRoutes.reportPhoto),
              child: form.photos.isNotEmpty
                  ? Row(
                      children: [
                        ...form.photos.take(3).map((f) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(f, width: 56, height: 56, fit: BoxFit.cover),
                          ),
                        )),
                        const SizedBox(width: 6),
                        Text(
                          '${form.photos.length} photo${form.photos.length > 1 ? 's' : ''}',
                          style: TextStyle(fontSize: 14, color: p.textSecondary),
                        ),
                      ],
                    )
                  : Text(l10n.noPhoto, style: TextStyle(fontSize: 14, color: p.textHint)),
            ),
            const SizedBox(height: 12),

            _SectionCard(
              label: l10n.reviewLocation,
              editLabel: l10n.edit,
              onEdit: () => context.go(AppRoutes.reportLocation),
              child: Row(
                children: [
                  Icon(PhosphorIconsDuotone.mapPin, color: p.urgent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${form.location.latitude.toStringAsFixed(5)}, ${form.location.longitude.toStringAsFixed(5)}',
                      style: TextStyle(fontSize: 13, color: p.textSecondary, fontFamily: 'monospace'),
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
                  ? Text(form.description, style: TextStyle(fontSize: 14, color: p.textPrimary, height: 1.5))
                  : Text(l10n.noDescription, style: TextStyle(fontSize: 14, color: p.textHint)),
            ),
            const SizedBox(height: 28),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: AppShapes.card(color: p.infoSoft, radius: AppShapes.radiusMd),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(PhosphorIconsRegular.info, color: p.info, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.submitDisclaimer,
                      style: TextStyle(fontSize: 12, color: p.info, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: AppShapes.card(color: p.urgentSoft, radius: AppShapes.radiusMd),
                child: Text(_error!, style: TextStyle(fontSize: 13, color: p.urgent)),
              ),
            ],

            const SizedBox(height: 20),
            SaButton(
              label: _uploadingPhoto ? l10n.uploadingPhoto : l10n.submitReport,
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
    final p = AppPalette.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.signInToSubmit, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p.textPrimary)),
          const SizedBox(height: 4),
          Text(l10n.signInReadySub, style: TextStyle(fontSize: 14, color: p.textSecondary)),
          const SizedBox(height: 20),

          Container(
            decoration: AppShapes.card(color: p.surfaceVariant, radius: AppShapes.radiusMd),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabs,
              indicator: AppShapes.card(color: p.surface, radius: AppShapes.radiusSm),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: p.ink,
              unselectedLabelColor: p.textHint,
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
                      decoration: InputDecoration(labelText: l10n.tabEmail, prefixIcon: Icon(PhosphorIconsRegular.envelopeSimple), isDense: true),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        isDense: true,
                        prefixIcon: Icon(PhosphorIconsRegular.lockSimple),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? PhosphorIconsRegular.eye : PhosphorIconsRegular.eyeClosed),
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
                      decoration: InputDecoration(labelText: l10n.phoneNumber, prefixIcon: Icon(PhosphorIconsRegular.phone), hintText: l10n.phoneHint, isDense: true),
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
              child: Text(auth.error!, style: TextStyle(fontSize: 12, color: p.urgent)),
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
    final p = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppShapes.card(color: p.surface, radius: AppShapes.radiusLg, borderColor: p.divider),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.textHint, letterSpacing: 0.8)),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: Text(editLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.ink)),
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
