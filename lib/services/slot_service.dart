// lib/services/slot_service.dart
import 'package:dio/dio.dart';
import '../models/slot.dart';
import 'api_client.dart';

class SlotService {
  const SlotService();

  /// GET /api/slots/?sport=<sportId>
  Future<List<Slot>> fetchBySport(int sportId) async {
    final Response res = await apiClient.get(
      '/slots/',
      queryParameters: {'sport': sportId},
    );

    // 如果后端以后改成 {"results":[...]} 也能兼容
    final dynamic payload = res.data;
    final List data = payload is Map ? payload['results'] as List : payload as List;

    return data
        .cast<dynamic>()
        .map((e) => Slot.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<Slot>> fetchBySportDate(int sportId, String date) async {
    final Response res = await apiClient.get(
      '/slots/',
      queryParameters: {'sport': sportId, 'date': date},
    );

    final dynamic payload = res.data;
    final List data = payload is Map ? payload['results'] as List : payload as List;

    return data
        .cast<dynamic>()
        .map((e) => Slot.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<Slot>> fetchByActivityDate(int activityId, String date) async {
    final Response res = await apiClient.get(
      '/slots/',
      queryParameters: {'activity': activityId, 'date': date},
    );

    final dynamic payload = res.data;
    final List data = payload is Map ? payload['results'] as List : payload as List;

    return data
        .cast<dynamic>()
        .map((e) => Slot.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> createSlot(
      int activityId,
      DateTime start,
      DateTime end,
      int capacity,
      double price,
      String title,
      String location,) async {
    await apiClient.post('/merchant/slots/', data: {
      'activity': activityId,
      'begins_at': start.toIso8601String(),
      'ends_at': end.toIso8601String(),
      'capacity': capacity,
      'price': price,
      'title': title,
      'location': location,
    });
  }
}

/// Global singleton – keep existing usage unchanged
const slotService = SlotService();
