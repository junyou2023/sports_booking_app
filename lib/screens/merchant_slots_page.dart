import 'package:flutter/material.dart';
import '../models/slot.dart';
import '../services/slot_service.dart';
import '../services/activity_service.dart';
import 'add_slot_page.dart';

class MerchantSlotsPage extends StatefulWidget {
  const MerchantSlotsPage({super.key});

  @override
  State<MerchantSlotsPage> createState() => _MerchantSlotsPageState();
}

class _MerchantSlotsPageState extends State<MerchantSlotsPage> {
  final List<Slot> _slots = [];
  String? _next;
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final page = await slotService.fetchMine(page: 1);
      setState(() {
        _slots
          ..clear()
          ..addAll(page.results);
        _next = page.next;
        _page = 1;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_next == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final page = await slotService.fetchMine(page: nextPage);
      setState(() {
        _slots.addAll(page.results);
        _next = page.next;
        _page = nextPage;
      });
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<int?> _pickActivity() async {
    try {
      final page = await activityService.fetchMine();
      final activities = page.results;
      if (activities.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('No activities found')));
        }
        return null;
      }
      return showDialog<int>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Select Activity'),
          children: activities
              .map((a) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, a.id),
                    child: Text(a.title),
                  ))
              .toList(),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to load activities')));
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Slots')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _slots.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(child: Text('No slots. Tap + to create.')),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _slots.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _slots.length) {
                          if (_loadingMore) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          } else if (_next != null) {
                            _loadMore();
                            return const SizedBox();
                          } else {
                            return const SizedBox(height: 80);
                          }
                        }
                        final s = _slots[index];
                        return Card(
                          margin:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(s.title),
                            subtitle: Text(
                                '${s.beginsAt.toLocal()} - ${s.endsAt.toLocal()}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(s.price.toStringAsFixed(2)),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () async {
                                    final updated = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => AddSlotPage(slot: s)),
                                    );
                                    if (updated == true) {
                                      await _refresh();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Slot updated')));
                                      }
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete slot?'),
                                        content: const Text(
                                            'This action cannot be undone.'),
                                        actions: [
                                          TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Cancel')),
                                          TextButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text('Delete')),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await slotService.deleteMerchantSlot(s.id);
                                      await _refresh();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Slot deleted')));
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final activityId = await _pickActivity();
          if (activityId != null) {
            final created = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddSlotPage(activityId: activityId)),
            );
            if (created == true) {
              await _refresh();
              if (mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Slot created')));
              }
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
