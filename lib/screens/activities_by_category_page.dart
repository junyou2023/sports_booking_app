import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../models/activity.dart';
import '../providers/activity_provider.dart';
import '../services/activity_service.dart';
import 'activity_detail_page.dart';
import '../widgets/activity_card.dart';

class ActivitiesByCategoryPage extends ConsumerStatefulWidget {
  final Category category;
  const ActivitiesByCategoryPage({super.key, required this.category});

  @override
  ConsumerState<ActivitiesByCategoryPage> createState() =>
      _ActivitiesByCategoryPageState();
}

class _ActivitiesByCategoryPageState
    extends ConsumerState<ActivitiesByCategoryPage> {
  final _items = <Activity>[];
  int _page = 1;
  bool _hasNext = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    debugPrint('view_category: id=${widget.category.id} name=${widget.category.name}');
  }

  Future<void> _refresh() async {
    final paginated =
        await activityService.fetchActivitiesByCategory(widget.category.id);
    setState(() {
      _items
        ..clear()
        ..addAll(paginated.results);
      _page = 1;
      _hasNext = paginated.next != null;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasNext) return;
    setState(() => _loadingMore = true);
    try {
      final paginated = await activityService.fetchActivitiesByCategory(
        widget.category.id,
        page: _page + 1,
      );
      setState(() {
        _page += 1;
        _hasNext = paginated.next != null;
        _items.addAll(paginated.results);
      });
    } finally {
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(activitiesByCategoryProvider(widget.category.id));
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $e'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => ref.refresh(activitiesByCategoryProvider(widget.category.id)), child: const Text('Retry')),
            ],
          ),
        ),
        data: (page) {
          if (_items.isEmpty) {
            _items.addAll(page.results);
            _hasNext = page.next != null;
          }
          if (_items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No activities found'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length + 1,
              itemBuilder: (context, i) {
                if (i == _items.length) {
                  if (_loadingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!_hasNext) return const SizedBox.shrink();
                  return Center(
                    child: ElevatedButton(
                      onPressed: _loadMore,
                      child: const Text('Load more'),
                    ),
                  );
                }
                final act = _items[i];
                return Semantics(
                  label: act.title,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ActivityCard(
                      title: act.title,
                      location: '',
                      price: act.basePrice,
                      rating: 0,
                      reviews: 0,
                      asset: act.imageUrl ?? act.image,
                      isFavorite: false,
                      onFavorite: () {},
                      onTap: () {
                        debugPrint('view_activity_from_category: categoryId=${widget.category.id} activityId=${act.id}');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ActivityDetailPage(activity: act),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
