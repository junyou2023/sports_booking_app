import 'package:dio/dio.dart';
import '../models/booking.dart';
import 'api_client.dart';

class PaymentService {
  Future<Map<String, dynamic>> createIntent(int slotId) async {
    final res = await apiClient.post('/payments/checkout/', data: {'slot': slotId});
    return res.data as Map<String, dynamic>;
  }

  Future<Booking> confirmIntent(String intentId) async {
    final res = await apiClient.get('/payments/checkout/', queryParameters: {'intent_id': intentId});
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }
}

final paymentService = PaymentService();
