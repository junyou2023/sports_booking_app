/// Global Dio instance configured with base-url and sane defaults.
/// All services import this instead of creating their own client.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

late Dio apiClient;

/// Call after dotenv.load to construct the client with the base URL and
/// attach authorization / refresh logic.
void initApiClient() {
  var base = dotenv.env['API_BASE_URL'] ?? '';
  if (base.isEmpty) {
    throw Exception('API_BASE_URL missing in .env');
  }
  if (!base.endsWith('/')) base += '/';

  final dio = Dio(
    BaseOptions(
      baseUrl: base,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  const storage = FlutterSecureStorage();

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'access');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (err, handler) async {
        if (err.response?.statusCode == 401) {
          final refresh = await storage.read(key: 'refresh');
          if (refresh != null) {
            try {
              final bare = Dio(BaseOptions(baseUrl: base));
              final res = await bare.post('auth/token/refresh/', data: {
                'refresh': refresh,
              });
              final access = res.data['access'] as String;
              await storage.write(key: 'access', value: access);
              err.requestOptions.headers['Authorization'] = 'Bearer $access';
              final retry = await dio.fetch(err.requestOptions);
              return handler.resolve(retry);
            } catch (_) {}
          }
        }
        handler.next(err);
      },
    ),
  );

  apiClient = dio;
}
