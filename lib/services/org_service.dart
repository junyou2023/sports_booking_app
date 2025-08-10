import 'package:dio/dio.dart';
import 'api_client.dart';

class OrgService {
  Future<List<Map<String, dynamic>>> fetchMine() async {
    final Response res = await apiClient.get('/accounts/merchant/orgs/me/');
    return (res.data as List).cast<Map<String, dynamic>>();
  }
}

final orgService = OrgService();
