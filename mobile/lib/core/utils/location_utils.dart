import 'package:geolocator/geolocator.dart';

/// Best-effort location for filtering categories by municipality — never
/// prompts for permission (categories should load instantly regardless of
/// location access); only returns a fix if permission was already granted
/// elsewhere in the app, and prefers the cached last-known fix over a fresh
/// GPS read.
Future<Position?> silentKnownPosition() async {
  try {
    final permission = await Geolocator.checkPermission();
    final granted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    if (!granted) return null;
    return await Geolocator.getLastKnownPosition();
  } catch (_) {
    return null;
  }
}
