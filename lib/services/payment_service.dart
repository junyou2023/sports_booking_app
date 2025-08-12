import 'package:dio/dio.dart';
import '../models/booking.dart';
import 'api_client.dart';

class PaymentService {
  Future<Map<String, dynamic>> createIntent(int slotId) async {
    try {
      final res = await apiClient.post('/payments/checkout/', data: {'slot': slotId});
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['detail'] != null) {
        throw Exception(data['detail'].toString());
      }
      final code = e.response?.statusCode;
      if (code != null) {
        throw Exception('HTTP $code');
      }
      throw Exception('Network error — please try again.');
    }
  }

  Future<Booking> confirmIntent(String intentId) async {
    final res = await apiClient.get('/payments/confirm/$intentId/');
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Booking> fetchBooking(int bookingId) async {
    final res = await apiClient.get('/bookings/' + bookingId.toString() + '/');
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }
}

final paymentService = PaymentService();
