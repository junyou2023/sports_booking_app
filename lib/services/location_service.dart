import 'package:geolocator/geolocator.dart';

/// Possible failures when requesting the user's location.
enum LocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
}

class LocationException implements Exception {
  final LocationFailure reason;
  LocationException(this.reason);
  @override
  String toString() => 'LocationException: $reason';
}

class LocationService {
  Future<LocationPermission> _ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw LocationException(LocationFailure.serviceDisabled);
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      throw LocationException(LocationFailure.permissionDenied);
    }
    if (perm == LocationPermission.deniedForever) {
      throw LocationException(LocationFailure.permissionPermanentlyDenied);
    }
    return perm;
  }

  Future<Position> current() async {
    await _ensurePermission();
    return Geolocator.getCurrentPosition();
  }

  Stream<Position> stream({LocationSettings? settings}) {
    return Geolocator.getPositionStream(locationSettings: settings ?? const LocationSettings());
  }
}

final locationService = LocationService();

