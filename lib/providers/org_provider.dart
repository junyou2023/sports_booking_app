import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/org_service.dart';

class OrgsNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  OrgsNotifier() : super(const AsyncValue.loading());

  int? selectedId;

  Future<void> load() async {
    if (state is AsyncData) return;
    try {
      final orgs = await orgService.fetchMine();
      if (selectedId == null && orgs.length == 1) {
        selectedId = orgs.first['id'] as int;
      }
      state = AsyncValue.data(orgs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void select(int id) {
    selectedId = id;
  }
}

final orgsProvider =
    StateNotifierProvider<OrgsNotifier, AsyncValue<List<Map<String, dynamic>>>>(
        (ref) => OrgsNotifier());

