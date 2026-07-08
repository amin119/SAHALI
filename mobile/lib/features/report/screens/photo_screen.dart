import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/step_bar.dart';
import '../../../shared/widgets/sa_button.dart';
import '../../../shared/widgets/sa_bottom_sheet.dart';
import '../viewmodels/report_form_provider.dart';

class PhotoScreen extends StatefulWidget {
  const PhotoScreen({super.key});
  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  final _picker = ImagePicker();

  Future<void> _pick(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) return;
    }
    if (!mounted) return;
    final form = context.read<ReportFormProvider>();
    if (form.photos.length >= ReportFormProvider.maxPhotos) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1200);
    if (picked == null || !mounted) return;
    context.read<ReportFormProvider>().addPhoto(File(picked.path));
  }

  void _remove(int index) => context.read<ReportFormProvider>().removePhoto(index);

  void _next() => context.go(AppRoutes.reportLocation);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final form = context.watch<ReportFormProvider>();
    final photos = form.photos;
    final canAdd = photos.length < ReportFormProvider.maxPhotos;
    final p = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.newReport),
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.go(AppRoutes.reportCategory),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: StepBar(step: 2, total: 6),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.addPhoto,
              style: Theme.of(context).textTheme.headlineLarge,
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 4),
            Text(
              l10n.addPhotoMax(ReportFormProvider.maxPhotos),
              style: TextStyle(fontSize: 14, color: p.textSecondary),
            ).animate().fadeIn(duration: 300.ms, delay: 60.ms),
            const SizedBox(height: 20),

            // Photo grid
            Expanded(
              child: photos.isEmpty
                  ? _EmptyState(onCamera: () => _pick(ImageSource.camera), onGallery: () => _pick(ImageSource.gallery))
                  : _PhotoGrid(
                      photos: photos,
                      canAdd: canAdd,
                      onRemove: _remove,
                      onCamera: () => _pick(ImageSource.camera),
                      onGallery: () => _pick(ImageSource.gallery),
                    ),
            ),

            if (photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canAdd ? () => _pick(ImageSource.gallery) : null,
                      icon: Icon(PhosphorIconsRegular.images, size: 18),
                      label: Text(l10n.gallery),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canAdd ? () => _pick(ImageSource.camera) : null,
                      icon: Icon(PhosphorIconsRegular.camera, size: 18),
                      label: Text(l10n.camera),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SaButton(
              label: photos.isNotEmpty ? l10n.nextConfirmLocation : l10n.skipPhoto,
              onPressed: _next,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCamera, required this.onGallery});
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppPalette.of(context);
    return GestureDetector(
      onTap: onCamera,
      child: Container(
        width: double.infinity,
        decoration: AppShapes.card(color: p.surface, radius: AppShapes.radiusLg, borderColor: p.border),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: AppShapes.card(color: p.infoSoft, radius: AppShapes.radiusLg),
              child: Icon(PhosphorIconsRegular.camera, color: p.info, size: 32),
            ).animate().scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1, 1),
                  duration: 360.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 16),
            Text(
              l10n.tapToTakePhoto,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(l10n.orChooseGallery, style: TextStyle(fontSize: 13, color: p.textSecondary)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.photos,
    required this.canAdd,
    required this.onRemove,
    required this.onCamera,
    required this.onGallery,
  });
  final List<File> photos;
  final bool canAdd;
  final void Function(int) onRemove;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: canAdd ? photos.length + 1 : photos.length,
      itemBuilder: (_, i) {
        if (i == photos.length) {
          return _AddTile(onCamera: onCamera, onGallery: onGallery);
        }
        return _PhotoTile(file: photos[i], onRemove: () => onRemove(i));
      },
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.file, required this.onRemove});
  final File file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(file, fit: BoxFit.cover),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: Icon(PhosphorIconsBold.x, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onCamera, required this.onGallery});
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppPalette.of(context);
    return GestureDetector(
      onTap: () => showSaBottomSheet(
        context,
        isScrollControlled: false,
        builder: (_) => SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(PhosphorIconsRegular.camera),
                title: Text(l10n.takePhoto),
                onTap: () { Navigator.pop(context); onCamera(); },
              ),
              ListTile(
                leading: Icon(PhosphorIconsRegular.images),
                title: Text(l10n.fromGallery),
                onTap: () { Navigator.pop(context); onGallery(); },
              ),
            ],
          ),
        ),
      ),
      child: Container(
        decoration: AppShapes.card(color: p.surface, radius: AppShapes.radiusMd, borderColor: p.border),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIconsRegular.plus, color: p.ink, size: 28),
            const SizedBox(height: 4),
            Text(l10n.addLabel, style: TextStyle(fontSize: 11, color: p.ink, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
