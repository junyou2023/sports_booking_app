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
          itemBuilder: (_, i) {
            final f = list[i];
            final subtitle = f.hasLocation
                ? '${f.lat!.toStringAsFixed(2)}, ${f.lng!.toStringAsFixed(2)}'
                : (f.address.isNotEmpty ? f.address : 'No location');
            return ListTile(
              title: Text(f.name),
              subtitle: Text(subtitle),
              onTap: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddFacilityPage(facility: f)),
                );
                if (updated == true) ref.invalidate(myFacilitiesProvider);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddFacilityPage()),
          );
          if (created == true) ref.invalidate(myFacilitiesProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
