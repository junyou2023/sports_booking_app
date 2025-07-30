import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../providers/search_providers.dart';
import '../providers/favorite_provider.dart';
import '../widgets/activity_card.dart';
import '../widgets/auth_sheet.dart';
import '../providers.dart';
import 'activity_detail_page.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _items = <Activity>[];
  int _page = 1;
  bool _hasNext = true;
  bool _loadingMore = false;
  late TextEditingController _controller;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
    ref.listen<String>(debouncedQueryProvider, (_, __) {
      setState(() {
        _items.clear();
        _page = 1;
        _hasNext = true;
      });
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasNext) return;
    setState(() => _loadingMore = true);
    try {
      final pageData =
          await ref.read(searchPageProvider(_page + 1).future);
      setState(() {
        _page += 1;
        _hasNext = pageData.next != null;
        _items.addAll(pageData.results);
      });
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final pageAsync = ref.watch(searchPageProvider(1));
    final favIds = ref.watch(favoriteIdsProvider);
    final suggestionsAsync = ref.watch(suggestionsProvider(query));

    Widget body = pageAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Network error'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.refresh(searchPageProvider(1)),
              child: const Text('Tap to retry'),
            ),
          ],
        ),
      ),
      data: (page) {
        final q = query.trim();
        if (q.isEmpty) {
          return const Center(child: Text('Try searching for activities'));
        }
        if (_lastQuery != q) {
          _items
            ..clear()
            ..addAll(page.results);
          _page = 1;
          _hasNext = page.next != null;
          _lastQuery = q;
        } else if (_items.isEmpty) {
          _items.addAll(page.results);
          _hasNext = page.next != null;
        }
        if (_items.isEmpty) {
          return const Center(child: Text('No results. Try different keywords.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            if (i == _items.length) {
              if (_loadingMore) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (!_hasNext) {
                return const SizedBox(height: 16);
              }
              return Center(
                child: ElevatedButton(
                  onPressed: _loadMore,
                  child: const Text('Load more'),
                ),
              );
            }
            final act = _items[i];
            return ActivityCard(
              title: act.title,
              location: '',
              price: act.basePrice,
              rating: 0,
              reviews: 0,
              asset: act.imageUrl ?? act.image,
              isFavorite: favIds.contains(act.id),
              onFavorite: () async {
                if (ref.read(authNotifierProvider) != AuthStatus.authenticated) {
                  showAuthSheet(context);
                  return;
                }
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
            );
          },
        );
      },
    );

    final suggestions = suggestionsAsync.maybeWhen(
      data: (list) => list,
      orElse: () => <String>[],
    );

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search activities',
            border: InputBorder.none,
          ),
          onChanged: (v) =>
              ref.read(searchQueryProvider.notifier).state = v,
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (suggestions.isNotEmpty && query.isNotEmpty)
            Container(
              color: Colors.white,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => ListTile(
                  title: Text(suggestions[i]),
                  onTap: () {
                    _controller.text = suggestions[i];
                    ref.read(searchQueryProvider.notifier).state = suggestions[i];
                  },
                ),
              ),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
