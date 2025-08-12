import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/slot.dart';
import '../providers.dart';
import '../services/slot_service.dart';
import '../services/activity_service.dart';
import 'add_slot_page.dart';

class MySlotsPage extends ConsumerWidget {
  const MySlotsPage({super.key});

  Future<int?> _pickActivity(BuildContext context) async {
    try {
      final page = await activityService.fetchMine();
      final activities = page.results;
      if (activities.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('No activities found')));
        }
        return null;
      }
      // ignore: use_build_context_synchronously
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
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to load activities')));
      }
      return null;
    }
  }

  Future<void> _deleteSlot(BuildContext context, WidgetRef ref, Slot s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete slot?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await slotService.deleteMerchantSlot(s.id);
      ref.invalidate(merchantSlotsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Slot deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(merchantSlotsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Slots')),
      body: slotsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (slots) => RefreshIndicator(
          onRefresh: () => ref.refresh(merchantSlotsProvider.future),
          child: slots.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 200),
                    Center(child: Text('No slots. Tap + to create.')),
                  ],
                )
              : ListView.builder(
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final s = slots[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(s.title),
                        subtitle:
                            Text('${s.beginsAt.toLocal()} - ${s.endsAt.toLocal()}'),
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
                                  ref.invalidate(merchantSlotsProvider);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Slot updated')));
                                  }
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteSlot(context, ref, s),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final activityId = await _pickActivity(context);
          if (activityId != null) {
            final created = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddSlotPage(activityId: activityId)),
            );
            if (created == true) {
              ref.invalidate(merchantSlotsProvider);
              if (context.mounted) {
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
