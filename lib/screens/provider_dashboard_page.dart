import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/activity_provider.dart';
import '../services/auth_service.dart';
import 'add_activity_page.dart';

class ProviderDashboardPage extends ConsumerWidget {
  const ProviderDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncActivities = ref.watch(activitiesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Dashboard')),
      body: asyncActivities.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(list[i].title),
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
            ref.invalidate(activitiesProvider);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
