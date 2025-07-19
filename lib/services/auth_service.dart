import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'api_client.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  final _googleSignIn = GoogleSignIn(scopes: ['email']);

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

  Future<void> register(String email, String password1, String password2) async {
    final Response res = await apiClient.post(
      '/auth/registration/',
      data: {
        'email': email,
        'password1': password1,
        'password2': password2,
      },
    );
    final access = res.data['access'];
    final refresh = res.data['refresh'];
    await _storage.write(key: 'access', value: access);
    await _storage.write(key: 'refresh', value: refresh);
    apiClient.options.headers['Authorization'] = 'Bearer $access';
  }

  Future<void> registerProvider(String email, String p1, String p2, String name, String phone, String address) async {
    final Response res = await apiClient.post(
      '/provider/register/',
      data: {
        'email': email,
        'password1': p1,
        'password2': p2,
        'company_name': name,
        'phone': phone,
        'address': address,
      },
    );
    final access = res.data['access'];
    final refresh = res.data['refresh'];
    await _storage.write(key: 'access', value: access);
    await _storage.write(key: 'refresh', value: refresh);
    apiClient.options.headers['Authorization'] = 'Bearer $access';
  }

  Future<void> loginWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return;
    final auth = await account.authentication;
    final Response res = await apiClient.post(
      '/auth/google/',
      data: {'id_token': auth.idToken},
    );
    final access = res.data['access'];
    final refresh = res.data['refresh'];
    await _storage.write(key: 'access', value: access);
    await _storage.write(key: 'refresh', value: refresh);
    apiClient.options.headers['Authorization'] = 'Bearer $access';
  }

  Future<void> logout() async {
    try {
      final refresh = await _storage.read(key: 'refresh');
      await apiClient.post('/auth/logout/', data: {'refresh': refresh});
    } finally {
      await _storage.delete(key: 'access');
      await _storage.delete(key: 'refresh');
      apiClient.options.headers.remove('Authorization');
    }
  }

  Future<void> requestPasswordReset(String email) async {
    await apiClient.post('/auth/password/reset/', data: {'email': email});
  }

  Future<void> refresh() async {
    final refresh = await _storage.read(key: 'refresh');
    if (refresh == null) return;
    final Response res = await apiClient.post(
      '/token/refresh/',
      data: {'refresh': refresh},
    );
    final access = res.data['access'];
    await _storage.write(key: 'access', value: access);
    apiClient.options.headers['Authorization'] = 'Bearer $access';
  }

  Future<String?> getToken() => _storage.read(key: 'access');
}

final authService = AuthService();
