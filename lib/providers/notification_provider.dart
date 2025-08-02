import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) => notificationService);

class UnreadCountNotifier extends StateNotifier<int> {
  UnreadCountNotifier(this.ref) : super(0) {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    refresh();
  }

  final Ref ref;
  Timer? _timer;

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
    this.items = const [],
    this.page = 1,
    this.hasNext = false,
    this.isLoading = false,
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

  factory NotificationListState.initial() => const NotificationListState();
}

String _errMsg(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) return data['detail'].toString();
    if (data is String && data.isNotEmpty) return data;
    final code = e.response?.statusCode ?? '';
    final msg = e.message ?? e.error?.toString() ?? '';
    return 'HTTP $code $msg'.trim();
  }
  return e.toString();
}

class NotificationListController extends StateNotifier<NotificationListState> {
  NotificationListController(this.ref) : super(NotificationListState.initial());

  final Ref ref;
  int? _inFlightPage;

  Future<void> loadFirst() async {
    state = state.copyWith(isLoading: true, page: 1, hasNext: false, error: null);
    try {
      final svc = ref.read(notificationServiceProvider);
      final pageData = await svc.listPaginated(page: 1);
      state = NotificationListState(
        items: pageData.items,
        page: 1,
        hasNext: pageData.hasNext,
        isLoading: false,
      );
      ref.read(unreadCountProvider.notifier).refresh();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _errMsg(e));
    } finally {
      _inFlightPage = null;
    }
  }

  Future<void> loadMore() async {
    if (!state.hasNext || state.isLoading) return;
    final next = state.page + 1;
    if (_inFlightPage == next) return;
    _inFlightPage = next;
    state = state.copyWith(isLoading: true);
    try {
      final svc = ref.read(notificationServiceProvider);
      final pageData = await svc.listPaginated(page: next);
      state = NotificationListState(
        items: [...state.items, ...pageData.items],
        page: next,
        hasNext: pageData.hasNext,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _errMsg(e));
    } finally {
      _inFlightPage = null;
    }
  }

  Future<void> markAllRead() async {
    final svc = ref.read(notificationServiceProvider);
    try {
      await svc.markAllRead();
      state = state.copyWith(
        items: [
          for (final n in state.items)
            AppNotification(
              id: n.id,
              ntype: n.ntype,
              title: n.title,
              body: n.body,
              data: n.data,
              createdAt: n.createdAt,
              readAt: n.readAt ?? DateTime.now(),
            )
        ],
        error: null,
      );
      ref.read(unreadCountProvider.notifier).refresh();
    } catch (e) {
      state = state.copyWith(error: _errMsg(e));
    }
  }

  Future<void> markRead(int id) async {
    final index = state.items.indexWhere((n) => n.id == id);
    if (index == -1) return;
    final svc = ref.read(notificationServiceProvider);
    try {
      await svc.markRead(id);
      final updated = [
        for (final n in state.items)
          n.id == id
              ? AppNotification(
                  id: n.id,
                  ntype: n.ntype,
                  title: n.title,
                  body: n.body,
                  data: n.data,
                  createdAt: n.createdAt,
                  readAt: n.readAt ?? DateTime.now(),
                )
              : n
      ];
      state = state.copyWith(items: updated, error: null);
      ref.read(unreadCountProvider.notifier).refresh();
    } catch (e) {
      state = state.copyWith(error: _errMsg(e));
    }
  }
}

final notificationListProvider =
    StateNotifierProvider<NotificationListController, NotificationListState>((ref) {
  return NotificationListController(ref);
});
