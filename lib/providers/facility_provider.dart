import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/facility.dart';
import '../services/facility_service.dart';
import 'location_provider.dart';

final selectedCategoriesProvider = StateProvider<List<String>>((ref) => []);
final radiusProvider = StateProvider<double>((ref) => 5000);

final facilitiesProvider = FutureProvider<List<Facility>>((ref) async {
  final cats = ref.watch(selectedCategoriesProvider);
  final radius = ref.watch(radiusProvider);
  final position = await ref.watch(locationProvider.future);
  return facilityService.fetchFacilities(
    cats,
    radius,
    position.latitude,
    position.longitude,
  );
});
