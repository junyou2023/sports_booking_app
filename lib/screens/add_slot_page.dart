import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/facility.dart';
import '../models/slot.dart';
import '../services/facility_service.dart';
import '../services/slot_service.dart';

class AddSlotPage extends StatefulWidget {
  final int? activityId;
  final Slot? slot;
  const AddSlotPage({super.key, this.activityId, this.slot})
      : assert(activityId != null || slot != null,
            'Either activityId or slot must be provided');

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
  List<Facility> _facilities = [];
  int? _facilityId;
  Map<String, String> _errors = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.slot != null) {
      final s = widget.slot!;
      start = s.beginsAt;
      end = s.endsAt;
      capacityCtrl.text = s.capacity.toString();
      priceCtrl.text = s.price.toStringAsFixed(2);
      titleCtrl.text = s.title;
      locationCtrl.text = s.location;
      _facilityId = s.facilityId;
    }
    facilityService.fetchMine().then((list) {
      if (mounted) setState(() => _facilities = list);
    });
  }

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
      appBar: AppBar(
          title: Text(widget.slot == null ? 'Create Slot' : 'Edit Slot')),
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
              DropdownButtonFormField<int>(
                value: _facilityId,
                decoration: InputDecoration(
                    labelText: 'Facility', errorText: _errors['facility'] ?? null),
                items: _facilities
                    .map((f) => DropdownMenuItem(value: f.id, child: Text(f.name)))
                    .toList(),
                onChanged: (v) => setState(() => _facilityId = v),
              ),
              TextFormField(
                controller: capacityCtrl,
                decoration: InputDecoration(
                    labelText: 'Capacity', errorText: _errors['capacity']),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Invalid capacity';
                  return null;
                },
              ),
              TextFormField(
                controller: priceCtrl,
                decoration:
                    InputDecoration(labelText: 'Price', errorText: _errors['price']),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 0) return 'Invalid price';
                  return null;
                },
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
                        setState(() => _errors.clear());
                        if (!_formKey.currentState!.validate()) return;
                        if (start == null || end == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Start and end times required')));
                          return;
                        }
                        if (!end!.isAfter(start!)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('End must be after start')));
                          return;
                        }
                        setState(() => _submitting = true);
                        try {
                          if (widget.slot == null) {
                            await slotService.createSlot(
                              widget.activityId!,
                              start!,
                              end!,
                              int.parse(capacityCtrl.text),
                              double.parse(priceCtrl.text),
                              titleCtrl.text,
                              locationCtrl.text,
                              facilityId: _facilityId,
                            );
                          } else {
                            await slotService.updateMerchantSlot(
                              widget.slot!.id,
                              facilityId: _facilityId,
                              beginsAt: start!,
                              endsAt: end!,
                              capacity: int.parse(capacityCtrl.text),
                              price: double.parse(priceCtrl.text),
                              title: titleCtrl.text,
                              location: locationCtrl.text,
                            );
                          }
                          if (context.mounted) Navigator.pop(context, true);
                        } on DioException catch (e) {
                          if (e.error is Map<String, List<String>>) {
                            final map = e.error as Map<String, List<String>>;
                            setState(() {
                              _errors =
                                  map.map((k, v) => MapEntry(k, v.join(', ')));
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to save slot')));
                          }
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
                    : Text(widget.slot == null ? 'Create' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
