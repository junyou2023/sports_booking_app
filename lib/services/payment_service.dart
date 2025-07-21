import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/booking.dart';

class PaymentService {
  Future<Map<String, dynamic>> createSession(int slotId) async {
    final res = await apiClient.post(
      '/payments/checkout/',
      data: {'slot': slotId},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Booking> confirmSession(String intentId) async {
    final res = await apiClient.get(
      '/payments/checkout/',
      queryParameters: {'intent_id': intentId},
    );
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }
}

final paymentService = PaymentService();
