import 'package:dio/dio.dart';
import '../models/facility.dart';
import 'api_client.dart';

class FacilityService {
  Future<List<Facility>> fetchFacilities(
      List<String> categories, double radius, double lat, double lng) async {
    final res = await apiClient.get('/facilities/', queryParameters: {
      'categories': categories.join(','),
      'radius': radius.toInt(),
      'near': '$lat,$lng',
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
}

final facilityService = FacilityService();
