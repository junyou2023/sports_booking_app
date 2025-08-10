import 'package:dio/dio.dart';

import 'api_client.dart';

class OrgService {
  Future<List<Map<String, dynamic>>> fetchMine() async {
    final Response res = await apiClient.get('/accounts/merchant/orgs/me/');
    final data = res.data;
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }
}

final orgService = OrgService();

