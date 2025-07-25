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
  Slot? _selectedSlot;
  bool _navigating = false;

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(activitySlotsProvider(widget.activity.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Select Slot')),
      bottomNavigationBar: _selectedSlot == null
          ? null
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _navigating ? null : _goToPayment,
                child: _navigating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
            ),
      body: slotsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
        data: (allSlots) {
          final dates = allSlots
              .map((s) => DateUtils.dateOnly(s.beginsAt))
              .toSet()
              .toList()
            ..sort();
          selectedDate ??= dates.isNotEmpty ? dates.first : null;

          if (dates.isEmpty) {
            return const Center(child: Text('No upcoming slots'));
          }

          return Column(
            children: [
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  itemCount: dates.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final date = dates[i];
                    final selected = DateUtils.isSameDay(date, selectedDate);
                    final label = '${date.month}/${date.day}';
                    return ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) => setState(() => selectedDate = date),
                    );
                  },
                ),
              ),
              Expanded(
                child: selectedDate == null
                    ? const SizedBox.shrink()
                    : _buildSlots(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSlots() {
    final asyncSlots = ref.watch(
      slotsByDateProvider(
        SlotsByDateParams(
          activityId: widget.activity.id,
          date: selectedDate!,
        ),
      ),
    );
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
              selected: _selectedSlot?.id == s.id,
              onTap: () {
                setState(() => _selectedSlot = s);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _goToPayment() async {
    if (_selectedSlot == null) return;
    setState(() => _navigating = true);
    final booking = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(slot: _selectedSlot!),
      ),
    );
    if (mounted) {
      setState(() => _navigating = false);
      if (booking != null) Navigator.pop(context, booking);
    }
  }
}
