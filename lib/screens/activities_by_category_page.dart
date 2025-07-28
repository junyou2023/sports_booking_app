import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../models/activity.dart';
import '../services/activity_service.dart';
import '../widgets/activity_card.dart';
import 'activity_detail_page.dart';

class ActivitiesByCategoryPage extends ConsumerWidget {
  final Category category;
  const ActivitiesByCategoryPage({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncActs = ref.watch(_activitiesByCategoryProvider(category.id));
    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: asyncActs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('No activities in this category yet'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final a = items[i];
                  final image = a.imageUrl ?? a.image;
                  return ActivityCard(
                    title: a.title,
                    location: '',
                    price: a.basePrice,
                    rating: 0,
                    reviews: 0,
                    asset: image,
                    isFavorite: false,
                    onFavorite: () {},
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActivityDetailPage(activity: a),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

final _activitiesByCategoryProvider =
    FutureProvider.family<List<Activity>, int>((ref, id) async {
  return activityService.fetchByCategory(id);
});

