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
}

/// Global singleton – keep existing usage unchanged
const slotService = SlotService();
