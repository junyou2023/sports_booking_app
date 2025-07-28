import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/activity_provider.dart';
import 'add_activity_page.dart';
import 'provider_facilities_page.dart';
import 'provider_categories_page.dart';
import 'add_slot_page.dart';

class ProviderDashboardPage extends ConsumerWidget {
  const ProviderDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncActivities = ref.watch(activitiesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.store),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ProviderFacilitiesPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ProviderCategoriesPage()),
              );
            },
          ),
        ],
      ),
      body: asyncActivities.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (page) => ListView.builder(
          itemCount: page.results.length,
          itemBuilder: (_, i) => ListTile(
            leading: (page.results[i].imageUrl != null &&
                    page.results[i].imageUrl!.isNotEmpty)
                ? Image.network(page.results[i].imageUrl!,
                    width: 50, fit: BoxFit.cover)
                : page.results[i].image.isNotEmpty
                    ? Image.network(page.results[i].image,
                        width: 50, fit: BoxFit.cover)
                    : null,
            title: Text(page.results[i].title),
            trailing: IconButton(
              icon: const Icon(Icons.schedule),
              onPressed: () async {
                final created = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddSlotPage(activityId: page.results[i].id),
                  ),
                );
                if (created == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Slot created')),
                  );
                }
              },
            ),
            onTap: () async {
              final updated = await Navigator.push(
                context,
                  MaterialPageRoute(
                    builder: (_) => AddActivityPage(activity: page.results[i]),
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
