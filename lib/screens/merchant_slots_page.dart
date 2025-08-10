import 'package:flutter/material.dart';
import '../models/slot.dart';
import '../services/slot_service.dart';
import '../utils/snackbar.dart';

class MerchantSlotsPage extends StatefulWidget { // R2
  final int activityId; // R2
  const MerchantSlotsPage({super.key, required this.activityId}); // R2

  @override
  State<MerchantSlotsPage> createState() => _MerchantSlotsPageState(); // R2
}

class _MerchantSlotsPageState extends State<MerchantSlotsPage> { // R2
  bool _loading = true; // R2
  List<Slot> _slots = []; // R2
  final Set<int> _selected = {}; // R2

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async { // R2
    setState(() => _loading = true);
    try {
      _slots = await slotService.listMerchantSlots(activityId: widget.activityId); // R2
    } catch (e) {
      if (mounted) showSnackBar(context, 'Failed to load slots: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _editSlot(Slot slot) async { // R2
    final priceCtrl = TextEditingController(text: slot.price.toString());
    final capCtrl = TextEditingController(text: slot.capacity.toString());
    DateTime begins = slot.beginsAt;
    DateTime ends = slot.endsAt;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, left: 16, right: 16, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: capCtrl,
                decoration: const InputDecoration(labelText: 'Capacity'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
    if (ok == true) {
      final price = double.tryParse(priceCtrl.text);
      final cap = int.tryParse(capCtrl.text);
      if (price == null || cap == null) {
        showSnackBar(context, 'Invalid input');
        return;
      }
      if (begins.isAfter(ends) || begins.isBefore(DateTime.now())) {
        showSnackBar(context, 'Invalid times');
        return;
      }
      await slotService.updateSlot(slot.id, price: price, capacity: cap, beginsAt: begins, endsAt: ends); // R2
      await _load();
    }
  }

  Future<void> _deleteSlot(int id) async { // R2
    await slotService.deleteSlot(id); // R2
    await _load();
  }

  Future<void> _bulkDelete() async { // R2
    if (_selected.isEmpty) return;
    await slotService.bulkDeleteSlots(_selected.toList()); // R2
    _selected.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Slots')), // R2
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _slots.length,
                itemBuilder: (context, i) {
                  final s = _slots[i];
                  final selected = _selected.contains(s.id);
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: CheckboxListTile(
                      value: selected,
                      onChanged: (_) {
                        setState(() {
                          if (selected) {
                            _selected.remove(s.id);
                          } else {
                            _selected.add(s.id);
                          }
                        });
                      },
                      title: Text(s.title),
                      subtitle: Text('${s.beginsAt} - ${s.endsAt}\n\$${s.price.toStringAsFixed(2)}'),
                      isThreeLine: true,
                      secondary: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editSlot(s),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteSlot(s.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      bottomNavigationBar: _selected.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  onPressed: _bulkDelete,
                  child: const Text('Bulk Close'),
                ),
              ),
            ),
    );
  }
}
