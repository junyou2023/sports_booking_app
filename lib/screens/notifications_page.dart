import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/app_notification.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_bell.dart';

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
    ref.read(notificationListProvider.notifier).loadFirst();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 200) {
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
      body: state.isLoading && state.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : RefreshIndicator(
                  onRefresh: () => ref.read(notificationListProvider.notifier).loadFirst(),
                  child: ListView.builder(
                    controller: _scroll,
                    itemCount: state.items.length + (state.hasNext ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= state.items.length) {
                        ref.read(notificationListProvider.notifier).loadMore();
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final n = state.items[index];
                      return ListTile(
                        leading: Icon(Icons.notifications, color: n.isRead ? Colors.grey : Colors.blue),
                        title: Text(n.title),
                        subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Text(timeago.format(n.createdAt)),
                        tileColor: n.isRead ? null : Colors.blue.withOpacity(0.05),
                        onTap: () {
                          // TODO: navigate based on n.data
                        },
                      );
                    },
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }
}
