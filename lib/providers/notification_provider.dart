import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_notification.dart';
import '../models/paginated.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) => notificationService);

class UnreadCountNotifier extends StateNotifier<int> {
  UnreadCountNotifier(this.ref) : super(0) {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    refresh();
  }

  Timer? _timer;
  final Ref ref;

  Future<void> refresh() async {
    try {
      final svc = ref.read(notificationServiceProvider);
      state = await svc.unreadCount();
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final unreadCountProvider = StateNotifierProvider<UnreadCountNotifier, int>((ref) {
  return UnreadCountNotifier(ref);
});

class NotificationListState {
  const NotificationListState({
    required this.items,
    required this.page,
    required this.hasNext,
    required this.isLoading,
    this.error,
  });

  final List<AppNotification> items;
  final int page;
  final bool hasNext;
  final bool isLoading;
  final String? error;

  NotificationListState copyWith({
    List<AppNotification>? items,
    int? page,
    bool? hasNext,
    bool? isLoading,
    String? error,
  }) {
    return NotificationListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasNext: hasNext ?? this.hasNext,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  factory NotificationListState.initial() =>
      const NotificationListState(items: [], page: 1, hasNext: true, isLoading: false, error: null);
}

class NotificationListController extends StateNotifier<NotificationListState> {
  NotificationListController(this.ref) : super(NotificationListState.initial());

  final Ref ref;

  Future<void> loadFirst() async {
    state = NotificationListState.initial().copyWith(isLoading: true);
    try {
      final svc = ref.read(notificationServiceProvider);
      final page = await svc.list(page: 1);
      state = state.copyWith(
        items: page.results,
        page: 1,
        hasNext: page.next != null,
        isLoading: false,
      );
      ref.read(unreadCountProvider.notifier).refresh();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasNext) return;
    state = state.copyWith(isLoading: true);
    try {
      final svc = ref.read(notificationServiceProvider);
      final page = await svc.list(page: state.page + 1);
      state = state.copyWith(
        items: [...state.items, ...page.results],
        page: state.page + 1,
        hasNext: page.next != null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAllRead() async {
    final svc = ref.read(notificationServiceProvider);
    await svc.markAllRead();
    state = state.copyWith(
        items: [for (final n in state.items) AppNotification(
          id: n.id,
          ntype: n.ntype,
          title: n.title,
          body: n.body,
          data: n.data,
          createdAt: n.createdAt,
          readAt: n.readAt ?? DateTime.now(),
        )]);
    ref.read(unreadCountProvider.notifier).refresh();
  }
}

final notificationListProvider =
    StateNotifierProvider<NotificationListController, NotificationListState>((ref) {
  return NotificationListController(ref);
});
