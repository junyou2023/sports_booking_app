import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../widgets/slot_card.dart';

/// Page showing slots created by the current merchant.
class MySlotsPage extends ConsumerWidget {
  const MySlotsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(mySlotsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Slots')),
      body: slotsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (err, _) => Center(
          child: Text(err.toString(), style: const TextStyle(color: Colors.red)),
        ),
        data: (slots) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: slots.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, i) => SlotCard(
            slot: slots[i],
            onTap: () {},
          ),
        ),
      ),
    );
  }
}
