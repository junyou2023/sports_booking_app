import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_booking_app/services/api_client.dart';
import 'package:sports_booking_app/services/payment_service.dart';

class TestAdapter implements HttpClientAdapter {
  TestAdapter(this.handler);
  final ResponseBody Function(RequestOptions) handler;
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<dynamic>? requestStream, Future<void>? cancelFuture) async {
    return handler(options);
  }
}

void main() {
  test('createIntent parses success response', () async {
    final dio = Dio();
    dio.httpClientAdapter = TestAdapter((_) {
      final data = {'client_secret': 'cs', 'intent_id': 'pi', 'booking_id': 1};
      return ResponseBody.fromString(jsonEncode(data), 200, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      });
    });
    apiClient = dio;

    final res = await paymentService.createIntent(1);
    expect(res.clientSecret, 'cs');
    expect(res.intentId, 'pi');
    expect(res.bookingId, 1);
  });

  test('createIntent throws with backend detail', () async {
    final dio = Dio();
    dio.httpClientAdapter = TestAdapter((_) {
      final data = {'detail': 'bad'};
      return ResponseBody.fromString(jsonEncode(data), 502, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      });
    });
    apiClient = dio;

    expect(
      () => paymentService.createIntent(1),
      throwsA(predicate((e) => e.toString().contains('bad'))),
    );
  });
}

