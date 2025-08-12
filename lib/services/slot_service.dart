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

  /// GET /api/my-slots/ - slots created by current user
  Future<List<Slot>> fetchMine() async {
    final Response res = await apiClient.get('/my-slots/');
    final dynamic payload = res.data;
    final List data = payload is Map ? payload['results'] as List : payload as List;
    return data
        .cast<dynamic>()
        .map((e) => Slot.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// POST /api/my-slots/ - create a new slot
  Future<Slot> create(Slot slot) async {
    final Response res = await apiClient.post('/my-slots/', data: slot.toJson());
    return Slot.fromJson(res.data as Map<String, dynamic>);
  }
}

/// Global singleton – keep existing usage unchanged
const slotService = SlotService();
