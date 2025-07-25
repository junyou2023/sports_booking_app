/// Global Dio instance configured with base-url and sane defaults.
/// All services import this instead of creating their own client.

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

late Dio apiClient;

/// Call after dotenv.load to construct the client with the base URL.
void initApiClient() {
  var base = dotenv.env['API_BASE_URL']!; // e.g. http://10.0.2.2:8000/api
  if (!base.endsWith('/')) base += '/';
  apiClient = Dio(
    BaseOptions(
      baseUrl: base,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
    ),
  );
}

final _storage = const FlutterSecureStorage();
const _retriedKey = 'retried';

Future<Response<dynamic>> _repeatRequest(RequestOptions req) {
  final opts = Options(
    method: req.method,
    headers: req.headers,
    responseType: req.responseType,
    contentType: req.contentType,
    extra: req.extra,
  );
  return apiClient.request(
    req.path,
    data: req.data,
    queryParameters: req.queryParameters,
    options: opts,
  );
}

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
        if (err.response?.statusCode == 401 && err.requestOptions.extra[_retriedKey] != true) {
          final refresh = await _storage.read(key: 'refresh');
          if (refresh != null) {
            try {
              final res = await apiClient.post('/token/refresh/', data: {'refresh': refresh});
              final access = res.data['access'] as String;
              await _storage.write(key: 'access', value: access);
              err.requestOptions.headers['Authorization'] = 'Bearer $access';
              err.requestOptions.extra[_retriedKey] = true;
              final cloneReq = await _repeatRequest(err.requestOptions);
              return handler.resolve(cloneReq);
            } catch (_) {
              await _storage.delete(key: 'access');
              await _storage.delete(key: 'refresh');
              err.requestOptions.headers.remove('Authorization');
              err.requestOptions.extra[_retriedKey] = true;
              final cloneReq = await _repeatRequest(err.requestOptions);
              return handler.resolve(cloneReq);
            }
          } else {
            await _storage.delete(key: 'access');
            err.requestOptions.headers.remove('Authorization');
            err.requestOptions.extra[_retriedKey] = true;
            final cloneReq = await _repeatRequest(err.requestOptions);
            return handler.resolve(cloneReq);
          }
        }
        handler.next(err);
      },
    ),
  );
}
