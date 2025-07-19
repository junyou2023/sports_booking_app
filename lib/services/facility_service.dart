import 'package:dio/dio.dart';
import '../models/facility.dart';
import 'api_client.dart';

class FacilityService {
  Future<List<Facility>> fetchFacilities(
      List<String> categories, double radius, double lat, double lng,
      {bool mine = false}) async {
    final res = await apiClient.get('/facilities/', queryParameters: {
      'categories': categories.join(','),
      if (radius > 0) 'radius': radius.toInt(),
      if (lat != 0 || lng != 0) 'near': '$lat,$lng',
      if (mine) 'mine': '1',
    });

    dynamic data = res.data;
    if (data is Map && data['features'] is List) {
      data = data['features'];
    }

    if (data is! List) {
      throw Exception('Unexpected response format');
    }

    return data
        .cast<Map<String, dynamic>>()
        .map(Facility.fromJson)
        .toList(growable: false);
  }

  Future<void> createFacility(String name, double lat, double lng, double radius,
      List<String> categories) async {
    await apiClient.post('/facilities/', data: {
      'name': name,
      'lat': lat,
      'lng': lng,
      'radius': radius,
      'categories': categories,
    });
  }
}

final facilityService = FacilityService();
