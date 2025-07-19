import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

final locationProvider = FutureProvider<Position>((ref) async {
  return locationService.getCurrent();
});
