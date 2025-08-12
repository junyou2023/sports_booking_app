import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:sports_booking_app/services/payment_service.dart';
import 'package:sports_booking_app/services/api_client.dart';

/// A [HttpClientAdapter] that always throws a [DioException] without a
/// response to simulate network errors.
class _ErrorAdapter extends HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future<dynamic>? cancelFuture) async {
    throw DioException(requestOptions: options, message: 'No connection');
  }
}

void main() {
  test('createIntent propagates connection error message', () async {
    // Override the global apiClient with a Dio instance that fails.
    apiClient = Dio(BaseOptions(baseUrl: 'http://example.com'))
      ..httpClientAdapter = _ErrorAdapter();

    expect(() => paymentService.createIntent(1),
        throwsA(predicate((e) => e.toString().contains('No connection'))));
  });
}
