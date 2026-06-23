import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/step_bar.dart';
import '../../../shared/widgets/sa_button.dart';
import '../viewmodels/report_form_provider.dart';

class PhotoScreen extends StatefulWidget {
  const PhotoScreen({super.key});
  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  File? _image;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final saved = context.read<ReportFormProvider>().photo;
    if (saved != null) _image = saved;
  }

  Future<void> _pick(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) return;
    }
    final picked = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1200);
    if (picked != null) {
      final file = File(picked.path);
      setState(() => _image = file);
      if (mounted) context.read<ReportFormProvider>().setPhoto(file);
    }
  }

  void _removePhoto() {
    setState(() => _image = null);
    context.read<ReportFormProvider>().setPhoto(null);
  }

  void _next() {
    context.go(AppRoutes.reportLocation);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.newReport),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go(AppRoutes.reportCategory)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), child: StepBar(step: 2, total: 6)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.addPhoto, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(l10n.addPhotoHint, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 24),

            Expanded(
              child: _image != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(_image!, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 12, right: 12,
                          child: GestureDetector(
                            onTap: _removePhoto,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    )
                  : GestureDetector(
                      onTap: () => _pick(ImageSource.camera),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const _CameraPlaceholder(),
                            const SizedBox(height: 16),
                            Text(l10n.tapToTakePhoto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text(l10n.orChooseGallery, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: Text(l10n.gallery),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: Text(l10n.camera),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SaButton(
              label: _image != null ? l10n.nextConfirmLocation : l10n.skipPhoto,
              onPressed: _next,
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
      child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 32),
    );
  }
}
