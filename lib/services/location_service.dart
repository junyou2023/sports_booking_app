import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrent() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('Location services disabled');
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }
    return Geolocator.getCurrentPosition();
  }
}

final locationService = LocationService();
