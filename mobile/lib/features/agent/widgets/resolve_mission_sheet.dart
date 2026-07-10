import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../features/report/providers/reports_provider.dart';
import '../../../shared/widgets/sa_button.dart';
import '../../../shared/widgets/sa_success_badge.dart';

/// Shown via `showSaBottomSheet<bool>()` from the agent mission detail
/// screen when a report is `in_progress`. Pops `true` once the report has
/// genuinely been resolved end-to-end (photo uploaded, status patched,
/// resolution report filed) — the caller refreshes the report on success.
class ResolveMissionSheet extends StatefulWidget {
  const ResolveMissionSheet({super.key, required this.reportId});
  final String reportId;

  @override
  State<ResolveMissionSheet> createState() => _ResolveMissionSheetState();
}

class _ResolveMissionSheetState extends State<ResolveMissionSheet> {
  final _picker = ImagePicker();
  final _commentCtrl = TextEditingController();
  final _materialsCtrl = TextEditingController();

  File? _photo;
  bool _submitting = false;
  bool _done = false;
  String? _error;

  // Per-step completion, so a retry after a partial failure doesn't redo
  // work that already succeeded.
  String? _uploadedPhotoUrl;
  bool _statusPatched = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _materialsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) return;
    }
    if (!mounted) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1200);
    if (picked == null || !mounted) return;
    setState(() => _photo = File(picked.path));
  }

  bool get _canSubmit => _photo != null && _commentCtrl.text.trim().isNotEmpty && !_submitting;

  Future<void> _submit() async {
    setState(() { _submitting = true; _error = null; });
    final reports = context.read<ReportsProvider>();
    try {
      _uploadedPhotoUrl ??= await reports.uploadPhoto(_photo!);
      if (!_statusPatched) {
        await reports.updateStatus(widget.reportId, 'resolved');
        _statusPatched = true;
      }
      try {
        await reports.createResolutionReport(
          widget.reportId,
          comment: _commentCtrl.text.trim(),
          materials: _materialsCtrl.text.trim().isEmpty ? null : _materialsCtrl.text.trim(),
          photoUrl: _uploadedPhotoUrl,
        );
      } on DioException catch (e) {
        // A 409 here means a resolution report already exists — most likely
        // a duplicate submit from a prior attempt. The report genuinely is
        // resolved either way, so treat this as success rather than an error.
        if (e.response?.statusCode != 409) rethrow;
      }
      if (!mounted) return;
      setState(() { _submitting = false; _done = true; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _submitting = false; _error = dioMessage(e); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppPalette.of(context);

    if (_done) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SaSuccessBadge(),
            const SizedBox(height: 16),
            Text(
              l10n.agentResolveSuccess,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.textPrimary),
            ),
            const SizedBox(height: 20),
            SaButton(label: l10n.agentConfirm, onPressed: () => Navigator.of(context).pop(true)),
          ],
        ),
      );
    }

    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomPad),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.agentResolveTitle,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.textPrimary),
            ),
            const SizedBox(height: 20),

            Text(l10n.agentResolvePhotoLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textHint)),
            const SizedBox(height: 8),
            if (_photo != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppShapes.radiusLg),
                    child: Image.file(_photo!, width: double.infinity, height: 160, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 6, right: 6,
                    child: GestureDetector(
                      onTap: () => setState(() => _photo = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(PhosphorIconsBold.x, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: SaOutlinedButton(
                      label: l10n.camera,
                      icon: PhosphorIconsRegular.camera,
                      onPressed: () => _pick(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SaOutlinedButton(
                      label: l10n.gallery,
                      icon: PhosphorIconsRegular.image,
                      onPressed: () => _pick(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),

            Text(l10n.agentResolveCommentLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textHint)),
            const SizedBox(height: 8),
            Container(
              decoration: AppShapes.card(color: p.surface, radius: AppShapes.radiusLg, borderColor: p.border),
              child: TextField(
                controller: _commentCtrl,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(l10n.agentResolveMaterialsLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textHint)),
            const SizedBox(height: 8),
            Container(
              decoration: AppShapes.card(color: p.surface, radius: AppShapes.radiusLg, borderColor: p.border),
              child: TextField(
                controller: _materialsCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: p.error, fontSize: 13)),
            ],

            const SizedBox(height: 20),
            SaButton(
              label: l10n.agentResolveSubmit,
              isLoading: _submitting,
              onPressed: _canSubmit ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}
