import 'package:flutter/material.dart';
import '../services/slot_service.dart';

class AddSlotPage extends StatefulWidget {
  final int activityId;
  const AddSlotPage({super.key, required this.activityId});

  @override
  State<AddSlotPage> createState() => _AddSlotPageState();
}

class _AddSlotPageState extends State<AddSlotPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? start;
  DateTime? end;
  final capacityCtrl = TextEditingController(text: '1');
  final priceCtrl = TextEditingController(text: '0');
  final titleCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    capacityCtrl.dispose();
    priceCtrl.dispose();
    titleCtrl.dispose();
    locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Slot')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: locationCtrl,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              TextFormField(
                controller: capacityCtrl,
                decoration: const InputDecoration(labelText: 'Capacity'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              ListTile(
                title: Text(start == null
                    ? 'Start Time'
                    : start!.toLocal().toString()),
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                      context: context,
                      initialDate: now,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)));
                  if (picked != null) {
                    final time = await showTimePicker(
                        context: context, initialTime: TimeOfDay.now());
                    if (time != null) {
                      setState(() =>
                          start = DateTime(picked.year, picked.month, picked.day,
                              time.hour, time.minute));
                    }
                  }
                },
              ),
              ListTile(
                title: Text(end == null
                    ? 'End Time'
                    : end!.toLocal().toString()),
                onTap: () async {
                  final now = start ?? DateTime.now();
                  final picked = await showDatePicker(
                      context: context,
                      initialDate: now,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)));
                  if (picked != null) {
                    final time = await showTimePicker(
                        context: context, initialTime: TimeOfDay.now());
                    if (time != null) {
                      setState(() =>
                          end = DateTime(picked.year, picked.month, picked.day,
                              time.hour, time.minute));
                    }
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitting
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        if (start == null || end == null) return;
                        setState(() => _submitting = true);
                        try {
                          await slotService.createSlot(
                            widget.activityId,
                            start!,
                            end!,
                            int.parse(capacityCtrl.text),
                            double.parse(priceCtrl.text),
                            titleCtrl.text,
                            locationCtrl.text,
                          );
                          if (context.mounted) Navigator.pop(context, true);
                        } finally {
                          if (mounted) setState(() => _submitting = false);
                        }
                      },
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
