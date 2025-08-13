import 'package:dio/dio.dart';
import '../models/booking.dart';
import 'api_client.dart';

class PaymentService {
  Future<Map<String, dynamic>> createIntent(int slotId) async {
    try {
      final res = await apiClient.post(
        'payments/checkout/',
        data: {'slot': slotId},
        options: Options(
          headers: {
            'Accept-Encoding': 'identity',
            'Connection': 'close',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['detail'] != null) {
        throw Exception(data['detail'].toString());
      }
      final msg = e.message ?? e.error?.toString() ?? 'network error';
      final code = e.response?.statusCode?.toString() ?? 'network';
      throw Exception('HTTP $code: $msg');
    }
  }

  Future<Booking> confirmIntent(String intentId) async {
    final res = await apiClient.get('payments/confirm/$intentId/');
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Booking> fetchBooking(int bookingId) async {
    final res = await apiClient.get('bookings/' + bookingId.toString() + '/');
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }
}

final paymentService = PaymentService();
