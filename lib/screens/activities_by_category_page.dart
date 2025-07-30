import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../models/activity.dart';
import '../providers/activity_provider.dart';
import '../services/activity_service.dart';
import 'activity_detail_page.dart';
import '../widgets/activity_card.dart';
import 'add_activity_page.dart';
import '../providers/favorite_provider.dart';
import '../providers.dart';
import '../widgets/auth_sheet.dart';

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
          // When there are no activities show an empty state with options
          if (_items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    const Text('No activities in this category'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                      child: const Text('Back'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final created = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddActivityPage()),
                      );
                      if (created == true) {
                        await _refresh();
                        ref.invalidate(
                          activitiesByCategoryProvider(widget.category.id),
                        );
                      }
                    },
                      child: const Text('Create one'),
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
                  // Adjust footer logic to avoid blank space when no more data
                  if (_loadingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!_hasNext) {
                    if (_items.isNotEmpty) {
                      return const SizedBox(height: 16);
                    }
                    return const Padding(
                      padding: EdgeInsets.all(16),
                        child: Center(child: Text('No more data')),
                    );
                  }
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
                      asset: act.imageUrl ?? act.image ?? 'assets/images/default.jpg',
                      isFavorite: ref.watch(favoriteIdsProvider).contains(act.id),
                      onFavorite: () async {
                        if (ref.read(authNotifierProvider) !=
                            AuthStatus.authenticated) {
                          showAuthSheet(context);
                          return;
                        }
                        await ref
                            .read(favoriteIdsProvider.notifier)
                            .toggle(context, act.id);
                      },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddActivityPage()),
          );
          if (created == true) {
            await _refresh();
            ref.invalidate(activitiesByCategoryProvider(widget.category.id));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
