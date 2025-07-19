import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/activity_provider.dart';
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
            leading: list[i].image.isNotEmpty
                ? Image.network(list[i].image, width: 50, fit: BoxFit.cover)
                : null,
            title: Text(list[i].title),
            onTap: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddActivityPage(activity: list[i]),
                ),
              );
              if (updated == true) {
                ref.invalidate(activitiesProvider);
              }
            },
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
