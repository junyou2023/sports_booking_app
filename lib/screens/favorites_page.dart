import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../providers/favorite_provider.dart';
import '../widgets/activity_card.dart';
import '../widgets/auth_sheet.dart';
import '../utils/snackbar.dart';
import 'home_page.dart';
import 'activity_detail_page.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  final _items = <Activity>[];
  int _page = 1;
  bool _hasNext = true;
  bool _loadingMore = false;

  Future<void> _refresh() async {
    final page = await favoriteService.listFavorites();
    setState(() {
      _items
        ..clear()
        ..addAll(page.results);
      _page = 1;
      _hasNext = page.next != null;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasNext) return;
    setState(() => _loadingMore = true);
    try {
      final page = await favoriteService.listFavorites(page: _page + 1);
      setState(() {
        _page += 1;
        _hasNext = page.next != null;
        _items.addAll(page.results);
      });
    } finally {
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageAsync = ref.watch(favoritesPageProvider(1));
    final favIds = ref.watch(favoriteIdsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: pageAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          if (e is UnauthorizedError) {
            return Center(
              child: ElevatedButton(
                onPressed: () => showAuthSheet(context),
                child: const Text('Login'),
              ),
            );
          }
          if (e is DioException) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${e.message}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => ref.refresh(favoritesPageProvider(1)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return Center(child: Text('Error: $e'));
        },
        data: (page) {
          if (_items.isEmpty) {
            _items.addAll(page.results);
            _hasNext = page.next != null;
          }
          final visible = _items.where((a) => favIds.contains(a.id)).toList();
          if (visible.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('还没有收藏'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage())),
                    child: const Text('去浏览活动'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                SliverList.builder(
                  itemCount: visible.length + 1,
                  itemBuilder: (context, i) {
                    if (i == visible.length) {
                      if (_loadingMore) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (!_hasNext) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: Text('没有更多数据')),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: _loadMore,
                          child: const Text('Load more'),
                        ),
                      );
                    }
                    final act = visible[i];
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: ActivityCard(
                        title: act.title,
                        location: '',
                        price: act.basePrice,
                        rating: 0,
                        reviews: 0,
                        asset: act.imageUrl ?? act.image ?? 'assets/images/default.jpg',
                        isFavorite: favIds.contains(act.id),
                        onFavorite: () async {
                          await ref
                              .read(favoriteIdsProvider.notifier)
                              .toggle(context, act.id);
                        },
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActivityDetailPage(activity: act),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
