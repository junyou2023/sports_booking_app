import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';

import '../models/facility.dart';
import '../models/category.dart';
import '../services/facility_service.dart';
import '../services/sports_service.dart' as sport_service;
import '../services/location_service.dart';
import '../utils/snackbar.dart';

class AddFacilityPage extends StatefulWidget {
  final Facility? facility;
  final FacilityService service;
  final sport_service.SportsService sportsService;
  final Future<List<Location>> Function(String) geocode;
  AddFacilityPage({
    super.key,
    this.facility,
    FacilityService? service,
    sport_service.SportsService? sportsSvc,
    this.geocode = locationFromAddress,
  })  : service = service ?? facilityService,
        sportsService = sportsSvc ?? sport_service.sportsService;

  @override
  State<AddFacilityPage> createState() => _AddFacilityPageState();
}

class _AddFacilityPageState extends State<AddFacilityPage> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  double? lat;
  double? lng;
  String? addressError;
  List<int> selectedCats = [];
  List<Category> categories = [];
  bool _submitting = false;
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    final f = widget.facility;
    if (f != null) {
      nameCtrl.text = f.name;
      lat = f.lat;
      lng = f.lng;
      selectedCats = f.categories.map(int.parse).toList();
    } else {
      _setCurrentLocation();
    }
    _loadFuture = _loadData();
  }

  Future<void> _loadData() async {
    categories = await widget.sportsService.fetchCategories();
  }

  Future<void> _setCurrentLocation() async {
    try {
      final pos = await locationService.getCurrent();
      setState(() {
        lat = pos.latitude;
        lng = pos.longitude;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location set to current position')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get current location: $e')),
      );
    }
  }

  Future<void> _setFromAddress() async {
    setState(() => addressError = null);
    try {
      final results = await widget.geocode(addressCtrl.text.trim());
      if (results.isNotEmpty) {
        setState(() {
          lat = results.first.latitude;
          lng = results.first.longitude;
          addressError = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Location set to ${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}')));
        }
      } else {
        setState(() {
          addressError = 'Address not found';
        });
      }
    } catch (e) {
      setState(() {
        addressError = 'Could not geocode address';
      });
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
                  if (lat != null && lng != null)
                    Text(
                        'Location set to ${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}'),
                  TextButton(
                    onPressed: _setCurrentLocation,
                    child: const Text('Use current location'),
                  ),
                  TextFormField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      labelText: 'Address (optional)',
                      errorText: addressError,
                    ),
                  ),
                  TextButton(
                    onPressed: _setFromAddress,
                    child: const Text('Use address'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final c in categories)
                        FilterChip(
                          label: Text(c.name),
                          selected: selectedCats.contains(c.id),
                          onSelected: (sel) {
                            setState(() {
                              if (sel) {
                                selectedCats.add(c.id);
                              } else {
                                selectedCats.remove(c.id);
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
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please set location (current or address).')),
                                );
                              }
                              return;
                            }
                            setState(() => _submitting = true);
                            try {
                              if (isEditing) {
                                await widget.service.updateFacility(
                                  widget.facility!.id,
                                  nameCtrl.text,
                                  lat!,
                                  lng!,
                                  selectedCats,
                                );
                              } else {
                                await widget.service.createFacility(
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
                              if (context.mounted) {
                                final msg = e.toString().isNotEmpty
                                    ? e.toString()
                                    : 'Unknown error';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Save facility failed: $msg')),
                                );
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
