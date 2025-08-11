import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';

import '../models/facility.dart';
import '../models/category.dart';
import '../services/facility_service.dart';
import '../services/sports_service.dart';
import '../services/location_service.dart';
import '../utils/snackbar.dart';

class AddFacilityPage extends StatefulWidget {
  final Facility? facility;
  const AddFacilityPage({super.key, this.facility});

  @override
  State<AddFacilityPage> createState() => _AddFacilityPageState();
}

class _AddFacilityPageState extends State<AddFacilityPage> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  double? lat;
  double? lng;
  List<String> selectedCats = [];
  List<Category> categories = [];
  bool _submitting = false;
  String? addressError;
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    final f = widget.facility;
    if (f != null) {
      nameCtrl.text = f.name;
      lat = f.lat;
      lng = f.lng;
      selectedCats = List<String>.from(f.categories);
    } else {
      _setCurrentLocation();
    }
    _loadFuture = _loadData();
  }

  Future<void> _loadData() async {
    categories = await sportsService.fetchCategories();
  }

  Future<void> _setCurrentLocation() async {
    try {
      final pos = await locationService.getCurrent();
      setState(() {
        lat = pos.latitude;
        lng = pos.longitude;
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get current location')),
      );
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.facility != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Facility' : 'Create Facility')),
      body: FutureBuilder(
        future: _loadFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: addressCtrl,
                          decoration: InputDecoration(
                            labelText: 'Address',
                            errorText: addressError,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          try {
                            final list = await locationFromAddress(addressCtrl.text);
                            if (list.isNotEmpty) {
                              setState(() {
                                lat = list.first.latitude;
                                lng = list.first.longitude;
                                addressError = null;
                              });
                            }
                          } catch (_) {
                            setState(() {
                              addressError = 'Could not resolve address';
                            });
                          }
                        },
                        child: const Text('Resolve address'),
                      ),
                    ],
                  ),
                  if (lat != null && lng != null)
                    Text(
                        'Location set to ${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}'),
                  TextButton(
                    onPressed: _setCurrentLocation,
                    child: const Text('Use current location'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final c in categories)
                        FilterChip(
                          label: Text(c.name),
                          selected: selectedCats.contains(c.id.toString()),
                          onSelected: (sel) {
                            setState(() {
                              if (sel) {
                                selectedCats.add(c.id.toString());
                              } else {
                                selectedCats.remove(c.id.toString());
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitting
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            if (lat == null || lng == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Location required')));
                              return;
                            }
                            setState(() => _submitting = true);
                            try {
                              if (isEditing) {
                                await facilityService.updateFacility(
                                  widget.facility!.id,
                                  nameCtrl.text,
                                  lat!,
                                  lng!,
                                  selectedCats,
                                );
                              } else {
                                await facilityService.createFacility(
                                  nameCtrl.text,
                                  lat!,
                                  lng!,
                                  selectedCats,
                                );
                              }
                              if (context.mounted) Navigator.pop(context, true);
                            } on DioException catch (e) {
                              if (context.mounted) {
                                showApiError(context, e, 'Save facility');
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Save facility failed: $e')));
                              }
                            } finally {
                              if (mounted) setState(() => _submitting = false);
                            }
                          },
                    child: _submitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(isEditing ? 'Save' : 'Create'),
                  ),
                  if (isEditing)
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete facility'),
                                  content: const Text('Are you sure?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                setState(() => _submitting = true);
                                try {
                                  await facilityService.deleteFacility(widget.facility!.id);
                                  if (context.mounted) Navigator.pop(context, true);
                                } on DioException catch (e) {
                                  if (context.mounted) showApiError(context, e, 'Delete facility');
                                } finally {
                                  if (mounted) setState(() => _submitting = false);
                                }
                              }
                            },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
