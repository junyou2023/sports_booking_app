/// Global Dio instance configured with base-url and sane defaults.
/// All services import this instead of creating their own client.

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final Dio apiClient = Dio(
  BaseOptions(
    baseUrl: dotenv.env['API_BASE_URL']!, // e.g. http://10.0.2.2:8000/api
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
    responseType: ResponseType.json,
  ),
);

final _storage = const FlutterSecureStorage();

/// Attach Authorization header if token is stored.
void initAuthInterceptor() {
  apiClient.interceptors.add(
    InterceptorsWrapper(onRequest: (options, handler) async {
      final token = await _storage.read(key: 'access');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    }),
  );
}
