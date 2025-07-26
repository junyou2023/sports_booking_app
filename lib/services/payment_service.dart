import 'package:dio/dio.dart';
import '../models/booking.dart';
import '../models/checkout_response.dart';
import 'api_client.dart';

class PaymentService {
  Future<CheckoutResponse> createIntent(int slotId) async {
    try {
      final res = await apiClient.post('/payments/checkout/', data: {'slot': slotId});
      return CheckoutResponse.fromJson(res.data);
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['detail']?.toString() ?? e.message)
          : e.message;
      throw Exception(msg ?? 'Payment checkout failed');
    }
  }

  Future<Booking> fetchBooking(int bookingId) async {
    final res = await apiClient.get('/bookings/' + bookingId.toString() + '/');
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }
}

final paymentService = PaymentService();
