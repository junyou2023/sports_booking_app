import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_booking_app/services/api_client.dart';
import 'package:sports_booking_app/services/payment_service.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test('createIntent surfaces Dio message when no response', () async {
    final mock = MockDio();
    apiClient = mock;
    when(() => mock.post(any(), data: any(named: 'data'))).thenThrow(
      DioException(
          requestOptions: RequestOptions(path: 'payments/checkout/'),
          message: 'No Internet'),
    );
    final svc = PaymentService();
    expect(() => svc.createIntent(1),
        throwsA(predicate((e) => e.toString().contains('No Internet'))));
  });
}
