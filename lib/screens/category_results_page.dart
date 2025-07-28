import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../providers/activity_by_category_provider.dart';
import '../widgets/activity_card.dart';
import 'activity_detail_page.dart';

class CategoryResultsPage extends ConsumerStatefulWidget {
  const CategoryResultsPage({super.key, required this.categoryId, required this.title});
  final int categoryId;
  final String title;

  @override
  ConsumerState<CategoryResultsPage> createState() => _CategoryResultsPageState();
}

class _CategoryResultsPageState extends ConsumerState<CategoryResultsPage> {
  int _page = 1;
  String? _ordering;
  final List<Activity> _activities = [];
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final page = await ref
        .read(activitiesByCategoryProvider(ActivityQuery(categoryId: widget.categoryId, ordering: _ordering, page: _page)).future);
    setState(() {
      if (_page == 1) _activities.clear();
      _activities.addAll(page.results);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activities.length + 1,
        itemBuilder: (_, i) {
          if (i < _activities.length) {
            final act = _activities[i];
            final img = act.imageUrl ?? act.image;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ActivityCard(
                title: act.title,
                location: '',
                price: act.basePrice,
                rating: 0,
                reviews: 0,
                asset: img,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ActivityDetailPage(activity: act)),
                ),
                onFavorite: () {},
                isFavorite: false,
              ),
            );
          }
          if (_loadingMore) {
            return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
          }
          return ElevatedButton(
            onPressed: () async {
              setState(() => _loadingMore = true);
              _page += 1;
              await _load();
              setState(() => _loadingMore = false);
            },
            child: const Text('Load More'),
          );
        },
      ),
    );
  }
}
