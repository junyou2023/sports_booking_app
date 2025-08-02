/// Global Dio instance configured with base-url and sane defaults.
/// All services import this instead of creating their own client.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

late Dio apiClient;

/// Call after dotenv.load to construct the client with the base URL.
void initApiClient() {
  var base = dotenv.env['API_BASE_URL'] ?? '';
  base = base.replaceAll(RegExp(r'/+\$'), '');
  apiClient = Dio(
    BaseOptions(
      baseUrl: '$base/',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
    ),
  );
  if (kDebugMode) {
    apiClient.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }
}

final _storage = const FlutterSecureStorage();
bool _refreshing = false;

/// Attach Authorization header if token is stored.
void initAuthInterceptor() {
  apiClient.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (err, handler) async {
        if (err.response?.statusCode == 401 && !_refreshing) {
          final refresh = await _storage.read(key: 'refresh');
          if (refresh != null) {
            _refreshing = true;
            try {
              final res = await apiClient.post('auth/token/refresh/', data: {'refresh': refresh});
              final access = res.data['access'];
              await _storage.write(key: 'access', value: access);
              apiClient.options.headers['Authorization'] = 'Bearer $access';
              err.requestOptions.headers['Authorization'] = 'Bearer $access';
              final cloneReq = await apiClient.fetch(err.requestOptions);
              _refreshing = false;
              return handler.resolve(cloneReq);
            } catch (_) {
              await _storage.delete(key: 'access');
              await _storage.delete(key: 'refresh');
              _refreshing = false;
            }
          }
        }
        handler.next(err);
      },
    ),
  );
}
