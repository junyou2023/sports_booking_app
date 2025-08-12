import 'package:dio/dio.dart';
import '../models/booking.dart';
import 'api_client.dart';

class PaymentService {
  Future<Map<String, dynamic>> createIntent(int slotId) async {
    try {
      final res = await apiClient.post(
        '/payments/checkout/',
        data: {'slot': slotId},
        options: Options(
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      String msg;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        msg = '支付服务超时，请稍后重试';
      } else if (e.response?.data is Map && e.response?.data['detail'] != null) {
        msg = e.response!.data['detail'].toString();
      } else {
        msg = '支付请求失败(${e.response?.statusCode})';
      }
      throw Exception(msg); // 兼容性增强点
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
