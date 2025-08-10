import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/org_service.dart';

final orgsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return orgService.fetchMine();
});

final selectedOrgProvider = StateProvider<int?>((ref) => null);
