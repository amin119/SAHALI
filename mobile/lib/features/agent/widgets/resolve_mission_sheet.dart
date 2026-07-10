import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../features/report/providers/reports_provider.dart';
import '../../../shared/widgets/sa_button.dart';
import '../../../shared/widgets/sa_success_badge.dart';

const _maxPhotos = 5;

/// Shown via `showSaBottomSheet<bool>()` from the agent mission detail
/// screen when a report is `in_progress`. Pops `true` once the report has
/// genuinely been resolved end-to-end (media uploaded, status patched,
/// resolution report filed) — the caller refreshes the report on success.
class ResolveMissionSheet extends StatefulWidget {
  const ResolveMissionSheet({super.key, required this.reportId});
  final String reportId;

  @override
  State<ResolveMissionSheet> createState() => _ResolveMissionSheetState();
}

class _ResolveMissionSheetState extends State<ResolveMissionSheet> {
  final _picker = ImagePicker();
  final _recorder = AudioRecorder();
  final _commentCtrl = TextEditingController();
  final _materialsCtrl = TextEditingController();

  final List<File> _photos = [];
  File? _video;
  File? _voiceNote;

  bool _recording = false;
  Duration _recordingElapsed = Duration.zero;
  Timer? _recordingTimer;

  bool _submitting = false;
  bool _done = false;
  String? _error;

  // Per-step completion, so a retry after a partial failure doesn't redo
  // work that already succeeded.
  final List<String> _uploadedPhotoUrls = [];
  String? _uploadedVideoUrl;
  String? _uploadedVoiceNoteUrl;
  bool _statusPatched = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _materialsCtrl.dispose();
    _recordingTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_photos.length >= _maxPhotos) return;
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) return;
    }
    if (!mounted) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1200);
    if (picked == null || !mounted) return;
    setState(() => _photos.add(File(picked.path)));
  }

  void _removePhoto(int index) => setState(() => _photos.removeAt(index));

  Future<void> _pickVideo(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) return;
    }
    if (!mounted) return;
    final picked = await _picker.pickVideo(source: source, maxDuration: const Duration(minutes: 2));
    if (picked == null || !mounted) return;
    setState(() => _video = File(picked.path));
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      final path = await _recorder.stop();
      _recordingTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _recording = false;
        if (path != null) _voiceNote = File(path);
      });
      return;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    if (!mounted) return;
    setState(() { _recording = true; _recordingElapsed = Duration.zero; });
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _recordingElapsed += const Duration(seconds: 1));
    });
  }

  void _removeVoiceNote() => setState(() => _voiceNote = null);

  bool get _canSubmit =>
      !_submitting &&
      !_recording &&
      _commentCtrl.text.trim().isNotEmpty &&
      (_photos.isNotEmpty || _video != null);

  Future<void> _submit() async {
    setState(() { _submitting = true; _error = null; });
    final reports = context.read<ReportsProvider>();
    try {
      for (var i = _uploadedPhotoUrls.length; i < _photos.length; i++) {
        _uploadedPhotoUrls.add(await reports.uploadFile(_photos[i]));
      }
      if (_video != null) {
        _uploadedVideoUrl ??= await reports.uploadFile(_video!);
      }
      if (_voiceNote != null) {
        _uploadedVoiceNoteUrl ??= await reports.uploadFile(_voiceNote!);
      }
      if (!_statusPatched) {
        await reports.updateStatus(widget.reportId, 'resolved');
        _statusPatched = true;
      }
      try {
        await reports.createResolutionReport(
          widget.reportId,
          comment: _commentCtrl.text.trim(),
          materials: _materialsCtrl.text.trim().isEmpty ? null : _materialsCtrl.text.trim(),
          photoUrls: _uploadedPhotoUrls,
          videoUrl: _uploadedVideoUrl,
          voiceNoteUrl: _uploadedVoiceNoteUrl,
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

  String _formatElapsed(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
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

            // ── Photos (multiple) ──────────────────────────────────────
            Text(l10n.agentResolvePhotoLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textHint)),
            const SizedBox(height: 4),
            Text(l10n.addPhotoMax(_maxPhotos), style: TextStyle(fontSize: 12, color: p.textHint)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < _photos.length; i++)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppShapes.radiusLg),
                        child: Image.file(_photos[i], width: 84, height: 84, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4, right: 4,
                        child: GestureDetector(
                          onTap: () => _removePhoto(i),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(PhosphorIconsBold.x, color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (_photos.length < _maxPhotos)
                  GestureDetector(
                    onTap: () => _showPhotoSourcePicker(context),
                    child: Container(
                      width: 84, height: 84,
                      decoration: AppShapes.card(color: p.surface, radius: AppShapes.radiusLg, borderColor: p.border),
                      child: Icon(PhosphorIconsRegular.plus, color: p.textHint, size: 24),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Video (single, optional) ────────────────────────────────
            Text(l10n.agentResolveVideoLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textHint)),
            const SizedBox(height: 8),
            if (_video != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: AppShapes.card(color: p.surface, radius: AppShapes.radiusLg, borderColor: p.border),
                child: Row(
                  children: [
                    Icon(PhosphorIconsRegular.videoCamera, size: 20, color: p.textPrimary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_video!.path.split(Platform.pathSeparator).last, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: p.textPrimary))),
                    GestureDetector(
                      onTap: () => setState(() => _video = null),
                      child: Icon(PhosphorIconsBold.x, size: 18, color: p.textHint),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: SaOutlinedButton(
                      label: l10n.camera,
                      icon: PhosphorIconsRegular.videoCamera,
                      onPressed: () => _pickVideo(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SaOutlinedButton(
                      label: l10n.gallery,
                      icon: PhosphorIconsRegular.image,
                      onPressed: () => _pickVideo(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),

            // ── Voice note (single, optional) ───────────────────────────
            Text(l10n.agentResolveVoiceLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textHint)),
            const SizedBox(height: 8),
            if (_voiceNote != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: AppShapes.card(color: p.surface, radius: AppShapes.radiusLg, borderColor: p.border),
                child: Row(
                  children: [
                    Icon(PhosphorIconsRegular.microphone, size: 20, color: p.textPrimary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(l10n.agentResolveVoiceLabel, style: TextStyle(fontSize: 13, color: p.textPrimary))),
                    GestureDetector(
                      onTap: _removeVoiceNote,
                      child: Icon(PhosphorIconsBold.x, size: 18, color: p.textHint),
                    ),
                  ],
                ),
              )
            else
              SaOutlinedButton(
                label: _recording
                    ? '${l10n.agentStopRecording} · ${_formatElapsed(_recordingElapsed)}'
                    : l10n.agentRecordVoice,
                icon: _recording ? PhosphorIconsFill.stopCircle : PhosphorIconsRegular.microphone,
                onPressed: _toggleRecording,
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

            const SizedBox(height: 8),
            if (_commentCtrl.text.trim().isNotEmpty && _photos.isEmpty && _video == null) ...[
              const SizedBox(height: 8),
              Text(l10n.agentVisualProofRequired, style: TextStyle(color: p.error, fontSize: 12)),
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

  Future<void> _showPhotoSourcePicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(PhosphorIconsRegular.camera),
              title: Text(l10n.camera),
              onTap: () { Navigator.of(ctx).pop(); _pickPhoto(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(PhosphorIconsRegular.image),
              title: Text(l10n.gallery),
              onTap: () { Navigator.of(ctx).pop(); _pickPhoto(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }
}
