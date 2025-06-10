// ========== lib/screens/categories_page.dart ==========
import 'package:flutter/material.dart';
import '../widgets/category_card.dart';

class CategoriesPage extends StatelessWidget {
  final List<Map<String, String>> allCategories;
  const CategoriesPage({super.key, required this.allCategories});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Categories')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: allCategories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisExtent: 140,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemBuilder: (_, i) => CategoryCard(
            title: allCategories[i]['label']!,
            asset: allCategories[i]['asset']!,
            onTap: () {
              // TODO: 跳转到对应类别详情
            },
          ),
        ),
      ),
    );
  }
}
