import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  Future<void> login(String email, String password) async {
    final Response res = await apiClient.post(
      '/auth/login/',
      data: {'email': email, 'password': password},
    );
    final access = res.data['access'];
    final refresh = res.data['refresh'];
    await _storage.write(key: 'access', value: access);
    await _storage.write(key: 'refresh', value: refresh);
    apiClient.options.headers['Authorization'] = 'Bearer $access';
  }

  Future<String?> getToken() => _storage.read(key: 'access');
}

final authService = AuthService();
