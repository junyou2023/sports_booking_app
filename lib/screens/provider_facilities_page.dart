import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/facility_provider.dart';
import 'add_facility_page.dart';

class ProviderFacilitiesPage extends ConsumerWidget {
  const ProviderFacilitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFacilities = ref.watch(myFacilitiesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Facilities')),
      body: asyncFacilities.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(list[i].name),
            subtitle: Text('${list[i].lat.toStringAsFixed(2)}, ${list[i].lng.toStringAsFixed(2)}'),
            onTap: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddFacilityPage(facility: list[i])),
              );
              if (updated == true) ref.invalidate(myFacilitiesProvider);
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddFacilityPage()),
          );
          if (created == true) ref.invalidate(myFacilitiesProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
