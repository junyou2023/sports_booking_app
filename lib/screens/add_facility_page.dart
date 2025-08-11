import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../models/facility.dart';
import '../models/category.dart';
import '../services/facility_service.dart';
import '../services/sports_service.dart' as sport_service;
import '../services/location_service.dart';
import '../utils/snackbar.dart';
import 'provider_registration_page.dart';

class AddFacilityPage extends StatefulWidget {
  final Facility? facility;
  final FacilityService service;
  final sport_service.SportsService sportsService;
  AddFacilityPage({
    super.key,
    this.facility,
    FacilityService? service,
    sport_service.SportsService? sportsSvc,
  })  : service = service ?? facilityService,
        sportsService = sportsSvc ?? sport_service.sportsService;

  @override
  State<AddFacilityPage> createState() => _AddFacilityPageState();
}

class _AddFacilityPageState extends State<AddFacilityPage> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final latCtrl = TextEditingController();
  final lngCtrl = TextEditingController();
  double? lat;
  double? lng;
  List<int> selectedCats = [];
  List<Category> categories = [];
  bool _submitting = false;
  bool _manualCoords = false;
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    final f = widget.facility;
    if (f != null) {
      nameCtrl.text = f.name;
      addressCtrl.text = f.address;
      lat = f.lat;
      lng = f.lng;
      if (lat != null) latCtrl.text = lat!.toString();
      if (lng != null) lngCtrl.text = lng!.toString();
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

  @override
  void dispose() {
    nameCtrl.dispose();
    addressCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
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
                  if (_manualCoords) ...[
                    TextFormField(
                      controller: latCtrl,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        return double.tryParse(v) == null ? 'Invalid' : null;
                      },
                      onChanged: (v) => lat = double.tryParse(v),
                    ),
                    TextFormField(
                      controller: lngCtrl,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        return double.tryParse(v) == null ? 'Invalid' : null;
                      },
                      onChanged: (v) => lng = double.tryParse(v),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _manualCoords = false);
                      },
                      child: const Text('Use address instead'),
                    ),
                  ] else ...[
                    TextFormField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(labelText: 'Address'),
                      validator: (v) {
                        if (lat == null && lng == null) {
                          return (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null;
                        }
                        return null;
                      },
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _manualCoords = true);
                      },
                      child: const Text('Change to manual coordinates'),
                    ),
                  ],
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
                            if (lat == null && lng == null &&
                                addressCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Address is required when location is missing')));
                              return;
                            }
                            setState(() => _submitting = true);
                            try {
                              if (isEditing) {
                                await widget.service.updateFacility(
                                  widget.facility!.id,
                                  nameCtrl.text,
                                  address: addressCtrl.text.trim(),
                                  lat: lat,
                                  lng: lng,
                                  categories: selectedCats,
                                );
                              } else {
                                await widget.service.createFacility(
                                  nameCtrl.text,
                                  address: addressCtrl.text.trim(),
                                  lat: lat,
                                  lng: lng,
                                  categories: selectedCats,
                                );
                              }
                              if (context.mounted) Navigator.pop(context, true);
                            } on DioException catch (e) {
                              if (context.mounted) {
                                final status = e.response?.statusCode;
                                if (status == 403) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                          'HTTP 403 · You need a provider account to create facilities.'),
                                      action: SnackBarAction(
                                        label: 'Become a Provider',
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const ProviderRegistrationPage(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                } else if (status == 400) {
                                  final data = e.response?.data;
                                  String detail = 'Bad request';
                                  if (data is Map && data.isNotEmpty) {
                                    final key = data.keys.first;
                                    final val = data[key];
                                    final msg = val is List && val.isNotEmpty
                                        ? val.first.toString()
                                        : val.toString();
                                    detail = '$key: $msg';
                                  } else if (data is String) {
                                    detail = data;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('HTTP 400 · $detail')),
                                  );
                                } else {
                                  showApiError(context, e, 'Save facility');
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Save facility failed: $e')),
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
