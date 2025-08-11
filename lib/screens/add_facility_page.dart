import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final latCtrl = TextEditingController();
  final lngCtrl = TextEditingController();
  double? lat;
  double? lng;
  String? latError;
  String? lngError;
  bool _manual = false;
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
      latCtrl.text = f.lat?.toString() ?? '';
      lngCtrl.text = f.lng?.toString() ?? '';
      selectedCats = f.categories.map(int.parse).toList();
    } else {
      _setCurrentLocation();
    }
    _loadFuture = _loadData();
  }

  void _validateCoords() {
    final latVal = double.tryParse(latCtrl.text);
    final lngVal = double.tryParse(lngCtrl.text);
    String? latErr;
    String? lngErr;
    if (latVal == null) {
      latErr = 'Required';
    } else if (latVal < -90 || latVal > 90) {
      latErr = 'Must be between -90 and 90';
    }
    if (lngVal == null) {
      lngErr = 'Required';
    } else if (lngVal < -180 || lngVal > 180) {
      lngErr = 'Must be between -180 and 180';
    }
    setState(() {
      lat = latErr == null ? latVal : null;
      lng = lngErr == null ? lngVal : null;
      latError = latErr;
      lngError = lngErr;
    });
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
          final nameValid = nameCtrl.text.trim().isNotEmpty;
          final canSubmit =
              nameValid && lat != null && lng != null && !_submitting;
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
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Use current location'),
                        selected: !_manual,
                        onSelected: (sel) {
                          if (sel) {
                            setState(() {
                              _manual = false;
                            });
                            _setCurrentLocation();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Enter coordinates manually'),
                        selected: _manual,
                        onSelected: (sel) {
                          if (sel) {
                            setState(() {
                              _manual = true;
                              latCtrl.text = lat?.toString() ?? '';
                              lngCtrl.text = lng?.toString() ?? '';
                              _validateCoords();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_manual) ...[
                    TextFormField(
                      controller: latCtrl,
                      decoration:
                          InputDecoration(labelText: 'Latitude', errorText: latError),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]'))
                      ],
                      onChanged: (_) => _validateCoords(),
                    ),
                    TextFormField(
                      controller: lngCtrl,
                      decoration:
                          InputDecoration(labelText: 'Longitude', errorText: lngError),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]'))
                      ],
                      onChanged: (_) => _validateCoords(),
                    ),
                    TextButton(
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                                  title: const Text('Paste coordinates from address'),
                                  content: const Text(
                                      'Use an online geocoding tool to convert an address to coordinates, then paste the latitude and longitude here.'),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK'))
                                  ],
                                ));
                      },
                      child: const Text('Paste coordinates from address'),
                    ),
                  ] else ...[
                    if (lat != null && lng != null)
                      Text(
                          'Location set to ${lat?.toStringAsFixed(5)}, ${lng?.toStringAsFixed(5)}'),
                    TextButton(
                      onPressed: _setCurrentLocation,
                      child: const Text('Use current location'),
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
                    onPressed: canSubmit
                        ? () async {
                            setState(() => _submitting = true);
                            final latVal = lat;
                            final lngVal = lng;
                            if (latVal == null || lngVal == null) {
                              setState(() => _submitting = false);
                              return;
                            }
                            try {
                              if (isEditing) {
                                await widget.service.updateFacility(
                                  widget.facility!.id,
                                  nameCtrl.text,
                                  latVal,
                                  lngVal,
                                  selectedCats,
                                );
                              } else {
                                await widget.service.createFacility(
                                  nameCtrl.text,
                                  latVal,
                                  lngVal,
                                  selectedCats,
                                );
                              }
                              if (context.mounted) {
                                Navigator.pop(context, true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(isEditing ? 'Facility saved' : 'Facility created')));
                              }
                            } on ArgumentError catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(content: Text(e.message)));
                              }
                            } on DioException catch (e) {
                              if (context.mounted) {
                                final status = e.response?.statusCode;
                                String msg = '';
                                final data = e.response?.data;
                                if (data is Map) {
                                  if (data['detail'] != null) {
                                    msg = data['detail'].toString();
                                  } else if (data.isNotEmpty) {
                                    msg = data.entries
                                        .map((entry) {
                                          final val = entry.value;
                                          final text = val is List && val.isNotEmpty
                                              ? val.first.toString()
                                              : val.toString();
                                          return '${entry.key}: $text';
                                        })
                                        .join(' · ');
                                  }
                                }
                                msg = msg.isNotEmpty ? msg : (e.message ?? '');
                                final text =
                                    status != null ? 'HTTP $status · $msg' : msg;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(text),
                                    action: status == 403
                                        ? SnackBarAction(
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
                                          )
                                        : null,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _submitting = false);
                            }
                          }
                        : null,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
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
