import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';
import '../repository/search_history_repository.dart';
import '../widgets/activity_card.dart';
import 'activity_detail_page.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scroll.addListener(() {
      if (_scroll.position.pixels >
          _scroll.position.maxScrollExtent - 200) {
        ref.read(searchResultProvider.notifier).loadMore();
      }
    });
  }

  Future<void> _loadHistory() async {
    final list = await searchHistoryRepository.load();
    if (mounted) {
      setState(() => _history = list);
    }
  }

  void _onChanged(String value) {
    ref.read(searchResultProvider.notifier).updateQuery(value);
    _debounce?.cancel();
    if (value.trim().length >= 2) {
      _debounce = Timer(const Duration(milliseconds: 300), () async {
        await ref.read(searchResultProvider.notifier).search();
        await searchHistoryRepository.add(value.trim());
        _loadHistory();
      });
    } else {
      ref.read(searchResultProvider.notifier).search();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchResultProvider);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search activities, sports or locations',
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      _onChanged('');
                    },
                  )
                : null,
          ),
          onChanged: _onChanged,
        ),
      ),
      body: state.isLoading && state.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${state.error}'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed:
                            () => ref.read(searchResultProvider.notifier).search(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : state.items.isEmpty
                  ? _buildHistory()
                  : _buildList(state),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
        return const Center(child: Text('No search history'));
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        children: _history
            .map(
              (h) => ActionChip(
                label: Text(h),
                onPressed: () {
                  _controller.text = h;
                  _onChanged(h);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildList(SearchResultState state) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      itemCount: state.items.length + 1,
      itemBuilder: (context, i) {
        if (i == state.items.length) {
          if (state.isLoading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (!state.hasNext) {
            return const SizedBox.shrink();
          }
          return const SizedBox(height: 16);
        }
        final act = state.items[i];
        return Padding(
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
    );
  }
}

