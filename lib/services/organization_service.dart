import 'package:dio/dio.dart';

import '../models/organization.dart';
import 'api_client.dart';

class OrganizationService {
  Future<List<Organization>> fetchMine() async {
    final Response res = await apiClient.get('/merchant/orgs/me/');
    final data = res.data as List;
    return data
        .map((e) => Organization.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final organizationService = OrganizationService();
