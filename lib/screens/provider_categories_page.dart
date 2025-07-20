import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sport_category_provider.dart';
import 'edit_category_page.dart';

class ProviderCategoriesPage extends ConsumerWidget {
  const ProviderCategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCats = ref.watch(sportCategoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: asyncCats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: %s' % e)),
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(list[i].fullPath),
            onTap: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditCategoryPage(all: list, category: list[i])),
              );
              if (updated == true) ref.invalidate(sportCategoriesProvider);
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EditCategoryPage(all: asyncCats.value ?? [])),
          );
          if (created == true) ref.invalidate(sportCategoriesProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
