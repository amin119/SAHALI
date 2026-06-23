import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/step_bar.dart';
import '../../../shared/widgets/sa_button.dart';
import '../viewmodels/report_form_provider.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});
  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  static const _tunisCenter = LatLng(36.8065, 10.1815);

  late LatLng _pinned;
  final _mapController = MapController();
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _pinned = context.read<ReportFormProvider>().location;
  }

  void _onMapTap(LatLng point) {
    setState(() => _pinned = point);
    context.read<ReportFormProvider>().setLocation(point);
  }

  Future<void> _goToMyLocation() async {
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locating = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _locating = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _locating = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _pinned = loc;
        _locating = false;
      });
      _mapController.move(loc, 15);
      if (mounted) context.read<ReportFormProvider>().setLocation(loc);
    } catch (_) {
      setState(() {
        _pinned = _tunisCenter;
        _locating = false;
      });
      _mapController.move(_tunisCenter, 15);
    }
  }

  void _confirm() {
    context.read<ReportFormProvider>().setLocation(_pinned);
    context.go(AppRoutes.reportDescription);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.newReport),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.reportPhoto),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: StepBar(step: 3, total: 6),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppColors.primaryContainer,
            child: Row(
              children: [
                const Icon(Icons.touch_app_outlined, color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.tapMapHint,
                    style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _pinned,
                    initialZoom: 15,
                    onTap: (_, point) => _onMapTap(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'tn.sahali.sahali',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _pinned,
                          width: 48,
                          height: 56,
                          child: const _PinIcon(),
                        ),
                      ],
                    ),
                  ],
                ),

                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'loc',
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primary,
                    onPressed: _locating ? null : _goToMyLocation,
                    child: _locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : const Icon(Icons.my_location_rounded),
                  ),
                ),
              ],
            ),
          ),

          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_pinned.latitude.toStringAsFixed(5)}, ${_pinned.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SaButton(label: l10n.confirmLocation, onPressed: _confirm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PinIcon extends StatelessWidget {
  const _PinIcon();
  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.location_pin,
      color: AppColors.primary,
      size: 48,
      shadows: [
        Shadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
      ],
    );
  }
}
