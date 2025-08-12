import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:sports_booking_app/services/api_client.dart';
import 'package:sports_booking_app/services/facility_service.dart';

class _FakeDio extends Dio {
  Map<String, dynamic>? lastQueryParameters;

  @override
  Future<Response<T>> get<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    lastQueryParameters = queryParameters;
    return Response<T>(
      data: [] as T,
      requestOptions: RequestOptions(path: path),
    );
  }
}

void main() {
  test('fetchFacilities omits empty categories param', () async {
    final fake = _FakeDio();
    apiClient = fake;
    await facilityService.fetchFacilities([], 0, 0, 0);
    expect(fake.lastQueryParameters?.containsKey('categories'), isFalse);
  });
}
