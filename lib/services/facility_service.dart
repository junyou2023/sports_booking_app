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

  Future<Facility> createFacility(
      String name, double lat, double lng, List<int> categories,
      {int radius = 1000}) async {
    final data = {
      'name': name,
      'lat': lat,
      'lng': lng,
      'radius': radius,
      'categories': categories,
    };
    try {
      final res = await apiClient.post('/merchant/facilities/', data: data);
      return Facility.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final res = await apiClient.post('/facilities/', data: data);
        return Facility.fromJson(res.data as Map<String, dynamic>);
      }
      rethrow;
    }
  }

  Future<List<Facility>> fetchMine() async {
    return fetchFacilities([], 0, 0, 0, mine: true);
  }

  Future<Facility> updateFacility(
      int id, String name, double lat, double lng, List<int> categories,
      {int radius = 1000}) async {
    final data = {
      'name': name,
      'lat': lat,
      'lng': lng,
      'radius': radius,
      'categories': categories,
    };
    try {
      final res = await apiClient.patch('/merchant/facilities/$id/', data: data);
      return Facility.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final res = await apiClient.patch('/facilities/$id/', data: data);
        return Facility.fromJson(res.data as Map<String, dynamic>);
      }
      rethrow;
    }
  }

  Future<void> deleteFacility(int id) async {
    try {
      await apiClient.delete('/merchant/facilities/$id/');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        await apiClient.delete('/facilities/$id/');
      } else {
        rethrow;
      }
    }
  }

  Future<List<Facility>> searchFacilities({required String query, int page = 1}) async {
    final res = await apiClient.get('/facilities/', queryParameters: {
      'q': query,
      'page': page,
    });
    dynamic data = res.data;
    if (data is Map && data['results'] is List) {
      data = data['results'];
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
