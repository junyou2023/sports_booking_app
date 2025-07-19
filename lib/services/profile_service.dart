import 'package:dio/dio.dart';

import '../models/profile.dart';
import 'api_client.dart';

class ProfileService {
  Future<Profile> fetch() async {
    final Response res = await apiClient.get('/profile/');
    return Profile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Profile> update(Map<String, dynamic> data) async {
    final Response res = await apiClient.put('/provider/profile/', data: data);
    return Profile.fromJson(res.data as Map<String, dynamic>);
  }
}

final profileService = ProfileService();
