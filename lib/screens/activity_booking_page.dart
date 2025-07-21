import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../models/slot.dart';
import '../providers.dart';
import '../widgets/slot_card.dart';
import 'payment_page.dart';

class ActivityBookingPage extends ConsumerStatefulWidget {
  const ActivityBookingPage({super.key, required this.activity});
  final Activity activity;

  @override
  ConsumerState<ActivityBookingPage> createState() => _ActivityBookingPageState();
}

class _ActivityBookingPageState extends ConsumerState<ActivityBookingPage> {
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Slot')),
      body: Column(
        children: [
          ListTile(
            title: Text(selectedDate == null
                ? 'Choose date'
                : '${selectedDate!.toLocal()}'.split(' ')[0]),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? now,
                firstDate: now,
                lastDate: now.add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => selectedDate = picked);
              }
            },
          ),
          Expanded(
            child: selectedDate == null
                ? const Center(child: Text('Select a date'))
                : _buildSlots(),
          ),
        ],
      ),
    );
  }

  Widget _buildSlots() {
    final dateStr = '${selectedDate!.year.toString().padLeft(4, '0')}-'
        '${selectedDate!.month.toString().padLeft(2, '0')}-'
        '${selectedDate!.day.toString().padLeft(2, '0')}';
    final asyncSlots = ref.watch(slotsByDateProvider((sportId: widget.activity.sport, date: dateStr)));
    return asyncSlots.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => Center(child: Text('Error: $e')),
      data: (slots) {
        if (slots.isEmpty) {
          return const Center(child: Text('No slots'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: slots.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final Slot s = slots[i];
            return SlotCard(
              slot: s,
              onTap: () async {
                final booking = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentPage(slot: s),
                  ),
                );
                if (booking != null) {
                  if (context.mounted) Navigator.pop(context, booking);
                }
              },
            );
          },
        );
      },
    );
  }
}
