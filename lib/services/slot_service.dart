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
}

/// Global singleton – keep existing usage unchanged
const slotService = SlotService();
