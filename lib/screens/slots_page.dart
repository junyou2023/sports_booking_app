import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sport.dart';
import '../providers.dart';
import '../widgets/slot_card.dart';

class SlotsPage extends ConsumerWidget {
  const SlotsPage({super.key, required this.sport});

  final Sport sport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(slotsProvider(sport.id));

    return Scaffold(
      appBar: AppBar(title: Text('${sport.name} slots')),
      body: slotsAsync.when(
        loading: () =>
        const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (err, _) =>
            Center(child: Text(err.toString(), style: const TextStyle(color: Colors.red))),
        data: (slots) => ListView.separated(
          padding: const EdgeInsets.all(16),
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemCount: slots.length,
          itemBuilder: (_, i) => SlotCard(
            slot: slots[i],
            onTap: () {
              // TODO: open booking bottom-sheet or details page
            },
          ),
        ),
      ),
    );
  }
}
