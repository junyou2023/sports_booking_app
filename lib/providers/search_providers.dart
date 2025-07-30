import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../models/paginated.dart';
import '../services/activity_service.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final debouncedQueryProvider = StreamProvider<String>((ref) {
  final controller = StreamController<String>();
  Timer? timer;
  final sub = ref.listen<String>(searchQueryProvider, (prev, next) {
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 300), () {
      if (!controller.isClosed) controller.add(next);
    });
  }, fireImmediately: true);
  ref.onDispose(() {
    timer?.cancel();
    controller.close();
    sub.close();
  });
  return controller.stream;
});

final searchPageProvider =
    FutureProvider.family<Paginated<Activity>, int>((ref, page) async {
  final query = await ref.watch(debouncedQueryProvider.future);
  final q = query.trim();
  if (q.isEmpty) {
    return Paginated(count: 0, next: null, previous: null, results: const []);
  }
  final cancel = CancelToken();
  ref.onDispose(() => cancel.cancel());
  return activityService.searchActivities(
    query: q,
    page: page,
    cancelToken: cancel,
  );
});

final suggestionsProvider =
    FutureProvider.family<List<String>, String>((ref, q) async {
  final query = q.trim();
  if (query.isEmpty) return <String>[];
  final cancel = CancelToken();
  ref.onDispose(() => cancel.cancel());
  return activityService.suggestActivities(query);
});
