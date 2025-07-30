import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../models/paginated.dart';
import '../services/activity_service.dart';

/// Holds the current search state and manages API requests.
class SearchResultState {
  const SearchResultState({
    required this.query,
    required this.items,
    required this.page,
    required this.hasNext,
    required this.isLoading,
    this.error,
    required this.token,
  });

  final String query;
  final List<Activity> items;
  final int page;
  final bool hasNext;
  final bool isLoading;
  final String? error;
  final int token;

  SearchResultState copyWith({
    String? query,
    List<Activity>? items,
    int? page,
    bool? hasNext,
    bool? isLoading,
    String? error,
    int? token,
  }) {
    return SearchResultState(
      query: query ?? this.query,
      items: items ?? this.items,
      page: page ?? this.page,
      hasNext: hasNext ?? this.hasNext,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      token: token ?? this.token,
    );
  }

  factory SearchResultState.initial() => const SearchResultState(
        query: '',
        items: [],
        page: 1,
        hasNext: false,
        isLoading: false,
        error: null,
        token: 0,
      );
}

final searchQueryProvider = StateProvider<String>((ref) => '');

class SearchResultController extends StateNotifier<SearchResultState> {
  SearchResultController(this.ref) : super(SearchResultState.initial());

  final Ref ref;

  void updateQuery(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
    state = state.copyWith(query: value);
  }

  bool _outdated(int tok) => tok != state.token;

  Future<void> search() async {
    final q = state.query.trim();
    final tok = state.token + 1;
    state = state.copyWith(
      items: [],
      page: 1,
      hasNext: true,
      isLoading: true,
      error: null,
      token: tok,
    );
    if (q.length < 2) {
      state = state.copyWith(isLoading: false, hasNext: false);
      return;
    }
    try {
      final Paginated<Activity> page =
          await activityService.searchActivities(query: q, page: 1);
      if (_outdated(tok)) return;
      state = state.copyWith(
        items: page.results,
        page: 1,
        hasNext: page.next != null,
        isLoading: false,
        token: tok,
      );
    } catch (e) {
      if (_outdated(tok)) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasNext) return;
    final q = state.query.trim();
    final tok = state.token;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final page = await activityService.searchActivities(
        query: q,
        page: state.page + 1,
      );
      if (_outdated(tok)) return;
      state = state.copyWith(
        items: [...state.items, ...page.results],
        page: state.page + 1,
        hasNext: page.next != null,
        isLoading: false,
      );
    } catch (e) {
      if (_outdated(tok)) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final searchResultProvider =
    StateNotifierProvider<SearchResultController, SearchResultState>((ref) {
  return SearchResultController(ref);
});
