// ========== lib/screens/categories_page.dart ==========
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/category_card.dart';
import '../providers/category_provider.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('All Categories')),
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (cats) => Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            itemCount: cats.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisExtent: 140,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemBuilder: (_, i) => CategoryCard(
              title: cats[i].name,
              asset: cats[i].icon,
              imageUrl: cats[i].imageUrl,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
  }
}
