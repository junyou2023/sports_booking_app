// POST /bookings  &  GET /bookings (mine)

import 'package:dio/dio.dart';
import '../models/booking.dart';
import 'api_client.dart';

class BookingService {
  Future<List<Booking>> fetchMine() async {
    final res = await apiClient.get('/bookings/');
    return (res.data as List)
        .cast<Map<String, dynamic>>()
        .map(Booking.fromJson)
        .toList(growable: false);
  }

  Future<Booking> create(int slotId, {int pax = 1}) async {
    final res = await apiClient.post(
      '/bookings/',
      data: {'slot_id': slotId, 'pax': pax},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Booking> fetchById(int id) async {
    final res = await apiClient.get('/bookings/' + id.toString() + '/');
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }
}

final bookingService = BookingService();
