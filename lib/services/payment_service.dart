import 'package:dio/dio.dart';
import '../models/booking.dart';
import 'api_client.dart';

class PaymentService {
  Future<Map<String, dynamic>> createIntent(int slotId) async {
    final res = await apiClient.post('/payments/checkout/', data: {'slot': slotId});
    return res.data as Map<String, dynamic>;
  }

  Future<Booking> fetchBooking(int bookingId) async {
    final res = await apiClient.get('/bookings/' + bookingId.toString() + '/');
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }
}

final paymentService = PaymentService();
