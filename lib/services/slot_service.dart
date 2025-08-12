// lib/services/slot_service.dart
import 'package:dio/dio.dart';
import '../models/slot.dart';
import '../models/paginated.dart';
import 'api_client.dart';

class SlotService {
  const SlotService();

  /// Format a [DateTime] with an explicit UTC offset so Django's
  /// `fromisoformat` can parse it as an aware datetime.
  String _iso(DateTime dt) =>
      dt.toUtc().toIso8601String().replaceFirst('Z', '+00:00');

  /// GET /api/slots/?sport=<sportId>
  Future<List<Slot>> fetchBySport(int sportId) async {
    final Response res = await apiClient.get(
      '/slots/',
      queryParameters: {'sport': sportId},
    );

    // Compatible if backend later switches to {"results": [...]} format
    final dynamic payload = res.data;
    final List data = payload is Map ? payload['results'] as List : payload as List;

    return data
        .cast<dynamic>()
        .map((e) => Slot.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// All upcoming slots for an activity. Uses `after` filter to
  /// only return slots from now onwards.
  Future<List<Slot>> fetchByActivity(int activityId) async {
    final Response res = await apiClient.get(
      '/slots/',
      queryParameters: {
        'activity': activityId,
        'after': _iso(DateTime.now()),
      },
    );

    final dynamic payload = res.data;
    final List data = payload is Map ? payload['results'] as List : payload as List;

    return data
        .cast<dynamic>()
        .map((e) => Slot.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<Slot>> fetchBySportDate(int sportId, DateTime after) async {
    final Response res = await apiClient.get(
      '/slots/',
      queryParameters: {
        'sport': sportId,
        'after': _iso(after),
      },
    );

    final dynamic payload = res.data;
    final List data = payload is Map ? payload['results'] as List : payload as List;

    return data
        .cast<dynamic>()
        .map((e) => Slot.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<Slot>> fetchByActivityDate(int activityId, DateTime date) async {
    final start = DateTime.utc(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final Response res = await apiClient.get(
      '/slots/',
      queryParameters: {
        'activity': activityId,
        'after': _iso(start),
        'before': _iso(end),
      },
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
      String location,
      {required int facilityId}) async {
    try {
      await apiClient.post('/merchant/slots/', data: {
        'activity': activityId,
        'facility': facilityId,
        'begins_at': start.toIso8601String(),
        'ends_at': end.toIso8601String(),
        'capacity': capacity,
        'price': price,
        'title': title,
        'location': location,
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 422) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          final map = <String, List<String>>{};
          data.forEach((key, value) {
            if (value is List) {
              map[key] = value.map((v) => v.toString()).toList();
            } else {
              map[key] = [value.toString()];
            }
          });
          throw DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: map,
          );
        }
      }
      throw e;
    }
  }

  Paginated<Slot> _parsePage(Object data) {
    if (data is List) {
      return Paginated.fromList(
        data.cast<Map<String, dynamic>>(),
        (j) => Slot.fromJson(j),
      );
    }
    if (data is Map<String, dynamic>) {
      return Paginated.fromJson(data, (j) => Slot.fromJson(j));
    }
    return Paginated(count: 0, next: null, previous: null, results: const []);
  }

  Future<Paginated<Slot>> fetchMine({int page = 1}) async {
    final res = await apiClient.get('/merchant/slots/', queryParameters: {'page': page});
    return _parsePage(res.data);
  }

  Future<void> updateMerchantSlot(int id, Map<String, dynamic> patch) async {
    await apiClient.patch('/merchant/slots/$id/', data: patch);
  }

  Future<void> deleteMerchantSlot(int id) async {
    await apiClient.delete('/merchant/slots/$id/');
  }
}

/// Global singleton – keep existing usage unchanged
const slotService = SlotService();
