import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/router/app_router.dart';
import '../../../core/tour/app_tour.dart';
import '../../../shared/widgets/step_bar.dart';
import '../../../shared/widgets/sa_button.dart';
import '../../../shared/widgets/tour_button.dart';
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
  final _mapKey = GlobalKey();
  final _nextBtnKey = GlobalKey();

  void _showTour(AppLocalizations l10n) {
    showScreenTour(context, [
      TourStep(
        targetKey: _mapKey,
        title: l10n.tourLocationMapTitle,
        description: l10n.tourLocationMapDesc,
        align: ContentAlign.bottom,
      ),
      TourStep(
        targetKey: _nextBtnKey,
        title: l10n.tourLocationNextTitle,
        description: l10n.tourLocationNextDesc,
        align: ContentAlign.top,
      ),
    ], doneLabel: l10n.tourDone);
  }

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
    final p = AppPalette.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.newReport),
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.go(AppRoutes.reportPhoto),
        ),
        actions: [TourButton(onPressed: () => _showTour(l10n))],
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
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: AppShapes.card(color: p.infoSoft, radius: AppShapes.radiusMd),
            child: Row(
              children: [
                Icon(PhosphorIconsRegular.handTap, color: p.info, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.tapMapHint,
                    style: TextStyle(fontSize: 13, color: p.info, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: KeyedSubtree(
              key: _mapKey,
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
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: AppShapes.card(
                      color: p.surface,
                      radius: AppShapes.radiusMd,
                      shadows: [BoxShadow(color: p.ink.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppShapes.radiusMd),
                        onTap: _locating ? null : _goToMyLocation,
                        child: Center(
                          child: _locating
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: p.ink),
                                )
                              : Icon(PhosphorIconsRegular.navigationArrow, color: p.ink),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              ),
            ),
          ),

          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: AppShapes.card(
              color: p.surface,
              radius: AppShapes.radiusXl,
              shadows: [BoxShadow(color: p.ink.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIconsDuotone.mapPin, color: p.urgent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_pinned.latitude.toStringAsFixed(5)}, ${_pinned.longitude.toStringAsFixed(5)}',
                        style: TextStyle(fontSize: 13, color: p.textSecondary, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                KeyedSubtree(key: _nextBtnKey, child: SaButton(label: l10n.confirmLocation, onPressed: _confirm)),
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
    final p = AppPalette.of(context);
    return Icon(
      Icons.location_pin,
      color: p.urgent,
      size: 48,
      shadows: [
        Shadow(color: p.urgent.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
      ],
    );
  }
}
