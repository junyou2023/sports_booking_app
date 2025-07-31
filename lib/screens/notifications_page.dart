import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/app_notification.dart';
import '../providers/notification_provider.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(notificationListProvider.notifier).loadFirst());
    _scroll.addListener(() {
      if (_scroll.position.pixels >
          _scroll.position.maxScrollExtent - 200) {
        ref.read(notificationListProvider.notifier).loadMore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationListProvider.notifier).markAllRead(),
            child: const Text('Mark all read'),
          )
        ],
      ),
      body: Builder(builder: (_) {
        if (state.isLoading && state.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('加载失败'),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      state.error!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(notificationListProvider.notifier).loadFirst(),
                  child: const Text('重试'),
                )
              ],
            ),
          );
        }
        if (!state.isLoading && state.items.isEmpty) {
          return const Center(child: Text('暂无通知'));
        }
        final showLoadMoreRow = state.items.isNotEmpty && state.hasNext;
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(notificationListProvider.notifier).loadFirst(),
          child: ListView.builder(
            controller: _scroll,
            itemCount: state.items.length + (showLoadMoreRow ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                if (!state.isLoading) {
                  ref.read(notificationListProvider.notifier).loadMore();
                }
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final n = state.items[index];
              return Dismissible(
                key: ValueKey(n.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) =>
                    ref.read(notificationListProvider.notifier).markRead(n.id),
                background: Container(
                  color: Colors.green,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.done, color: Colors.white),
                ),
                child: ListTile(
                  leading: Icon(Icons.notifications,
                      color: n.isRead ? Colors.grey : Colors.blue),
                  title: Text(n.title),
                  subtitle: Text(n.body,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text(timeago.format(n.createdAt)),
                  tileColor: n.isRead ? null : Colors.blue.withOpacity(0.05),
                  onTap: () =>
                      ref.read(notificationListProvider.notifier).markRead(n.id),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }
}
