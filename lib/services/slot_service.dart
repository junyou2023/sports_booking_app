// lib/services/slot_service.dart
import 'package:dio/dio.dart';
import '../models/slot.dart';
import 'api_client.dart';

class SlotService {
  const SlotService();

  /// Format [dt] as RFC3339 including timezone offset or Z. // R1
  String _iso(DateTime dt) {
    final iso = dt.toIso8601String(); // R1
    if (iso.endsWith('Z')) return iso; // R1
    final offset = dt.timeZoneOffset; // R1
    final sign = offset.isNegative ? '-' : '+'; // R1
    final hours = offset.inHours.abs().toString().padLeft(2, '0'); // R1
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0'); // R1
    return '$iso$sign$hours:$minutes'; // R1
  }

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
      String location,) async {
    await apiClient.post('/merchant/slots/', data: {
      'activity': activityId,
      'begins_at': _iso(start), // R1
      'ends_at': _iso(end), // R1
      'capacity': capacity,
      'price': price,
      'title': title,
      'location': location,
    });
  }

  Future<List<Slot>> listMerchantSlots({int? activityId}) async { // R2
    final res = await apiClient.get('/merchant/slots/', queryParameters: { // R2
      if (activityId != null) 'activity': activityId, // R2
    }); // R2
    final List data = res.data as List; // R2
    return data.map((e) => Slot.fromJson(e as Map<String, dynamic>)).toList(); // R2
  }

  Future<void> updateSlot( // R2
    int id, {
    DateTime? beginsAt,
    DateTime? endsAt,
    double? price,
    int? capacity,
    String? title,
    String? location,
    int? facility,
  }) async {
    final body = <String, dynamic>{};
    if (beginsAt != null) body['begins_at'] = _iso(beginsAt); // R2
    if (endsAt != null) body['ends_at'] = _iso(endsAt); // R2
    if (price != null) body['price'] = price; // R2
    if (capacity != null) body['capacity'] = capacity; // R2
    if (title != null) body['title'] = title; // R2
    if (location != null) body['location'] = location; // R2
    if (facility != null) body['facility'] = facility; // R2
    await apiClient.patch('/merchant/slots/' + id.toString() + '/', data: body); // R2
  }

  Future<void> deleteSlot(int id) async { // R2
    await apiClient.delete('/merchant/slots/' + id.toString() + '/'); // R2
  }

  Future<Map<String, dynamic>> bulkDeleteSlots(List<int> ids) async { // R2
    final res = await apiClient.post('/merchant/slots/bulk-delete/', data: {'ids': ids}); // R2
    return res.data as Map<String, dynamic>; // R2
  }

  Future<void> bulkCreateSlots(List<Map<String, dynamic>> slots) async { // R2
    await apiClient.post('/slots/bulk/', data: {'slots': slots}); // R2
  }
}

/// Global singleton – keep existing usage unchanged
const slotService = SlotService();
