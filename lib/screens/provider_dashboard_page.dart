import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/facility_service.dart';
import '../services/auth_service.dart';
import 'add_activity_page.dart';

final myFacilitiesProvider = FutureProvider((ref) async {
  return facilityService.fetchFacilities([], 0, 0, 0, mine: true);
});

class ProviderDashboardPage extends ConsumerWidget {
  const ProviderDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFacilities = ref.watch(myFacilitiesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Dashboard')),
      body: asyncFacilities.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(list[i].name),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddActivityPage()),
          );
          if (created == true) {
            ref.invalidate(myFacilitiesProvider);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
