/// Global Dio instance configured with base-url and sane defaults.
/// All services import this instead of creating their own client.

import 'dart:io' show Platform; // needed to detect desktop platforms

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../screens/login_page.dart';

late Dio apiClient;

// unique key for navigation without BuildContext
final apiClientNavKey = GlobalKey<NavigatorState>();

/// Adjust base URL for non-Android platforms where Android's `10.0.2.2`
/// (emulator localhost) is unreachable. When running on Web, desktop or iOS
/// and the env contains `10.0.2.2`, swap to `127.0.0.1`.
@visibleForTesting
String adjustBaseUrl(String base,
    {bool? webOverride, bool? desktopOverride, bool? iosOverride}) {
  final isWeb = webOverride ?? kIsWeb;
  final isDesktop = desktopOverride ??
      (!isWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows));
  final isIOS = iosOverride ?? (!isWeb && Platform.isIOS);
  if ((isWeb || isDesktop || isIOS) && base.contains('10.0.2.2')) {
    return base.replaceFirst('10.0.2.2', '127.0.0.1');
  }
  return base;
}

/// Call after dotenv.load to construct the client with the base URL.
Future<void> initApiClient() async {
  var base = dotenv.env['API_BASE_URL'] ?? '';
  if (base.isEmpty) {
    throw Exception('API_BASE_URL missing in mobile/.env');
  }
  base = adjustBaseUrl(base);
  if (!base.endsWith('/')) base += '/';
  apiClient = Dio(
    BaseOptions(
      baseUrl: base,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
      responseType: ResponseType.json,
    ),
  );
  if (kDebugMode) {
    apiClient.interceptors
        .add(LogInterceptor(requestBody: true, responseBody: true));
  }
}

final _storage = const FlutterSecureStorage();
Future<void>? _refreshing; // serialize token refreshes (covers: 并发刷新互斥)

/// Attach Authorization header if token is stored.
void initAuthInterceptor() {
  apiClient.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // BUG: sending expired access token to refresh endpoint => 401
        if (!options.path.contains('token/refresh')) {
          final token = await _storage.read(key: 'access');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (err, handler) async {
        if (err.response?.statusCode == 401 &&
            !err.requestOptions.path.contains('token/refresh') &&
            err.requestOptions.extra['__retry'] != true) {
          final refresh = await _storage.read(key: 'refresh');
          if (refresh != null) {
            try {
              // BUG: concurrent 401s triggered multiple refresh calls
              // FIX: queue refresh so only one request runs at a time
              _refreshing ??= apiClient
                  .post('auth/token/refresh/', data: {'refresh': refresh})
                  .then((res) async {
                final data = res.data as Map<String, dynamic>;
                final access = data['access'] as String;
                await _storage.write(key: 'access', value: access);
                if (data['refresh'] != null) {
                  await _storage.write(key: 'refresh', value: data['refresh'] as String);
                }
              }).catchError((_) async {
                // BUG: leaving interceptor without calling handler closed connection on My Bookings
                // FIX: logout then propagate original error so caller sees failure (covers: 刷新失败)
                await _storage.deleteAll();
                apiClientNavKey.currentState?.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
                throw _;
              }).whenComplete(() => _refreshing = null);

              await _refreshing;
              final access = await _storage.read(key: 'access');
              if (access == null) {
                return handler.reject(err);
              }
              err.requestOptions.headers['Authorization'] = 'Bearer $access';
              err.requestOptions.extra['__retry'] = true; // mark to avoid loops
              final cloneReq = await apiClient.fetch(err.requestOptions);
              return handler.resolve(cloneReq);
            } catch (_) {
              return handler.reject(err);
            }
          }
        }
        handler.next(err);
      },
    ),
  );
}
