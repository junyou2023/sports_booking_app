import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/activity.dart';
import '../models/category.dart';
import '../models/sport.dart';
import '../models/variant.dart';
import '../providers/org_provider.dart';
import '../services/activity_service.dart';
import '../services/sports_service.dart';
import 'provider_registration_page.dart';
import '../utils/snackbar.dart';

class AddActivityPage extends ConsumerStatefulWidget {
  final Activity? activity;
  final ActivityService service;
  AddActivityPage({super.key, this.activity, ActivityService? service})
      : service = service ?? activityService;

  @override
  ConsumerState<AddActivityPage> createState() => _AddActivityPageState();
}

class _AddActivityPageState extends ConsumerState<AddActivityPage> {
  final _formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final durationCtrl = TextEditingController(text: '60');

  int? sportId;
  int? disciplineId;
  int? variantId;
  int difficulty = 1;
  bool _submitting = false;
  XFile? _imageFile;
  String? _existingImage;
  Map<String, String> fieldErrors = {};
  bool _formValid = false;

  late Future<void> _loadFuture;
  List<Sport> sports = [];
  List<Category> categories = [];
  List<Variant> variants = [];

  @override
  void initState() {
    super.initState();
    final a = widget.activity;
    if (a != null) {
      sportId = a.sport;
      disciplineId = a.discipline;
      variantId = a.variant;
      titleCtrl.text = a.title;
      descCtrl.text = a.description;
      priceCtrl.text = a.basePrice.toStringAsFixed(2);
      durationCtrl.text = a.duration.toString();
      _existingImage = a.imageUrl?.isNotEmpty == true ? a.imageUrl : a.image;
      difficulty = a.difficulty;
      _formValid = true;
    }
    _loadFuture = _loadData();
  }

  Future<void> _loadData() async {
    sports = await sportsService.fetchSports();
    categories = await sportsService.fetchCategories();
    variants = await sportsService.fetchVariants();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    durationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Activity')),
      body: FutureBuilder(
        future: _loadFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final orgsAsync = ref.watch(orgsProvider);
          final selectedOrg = ref.watch(selectedOrgProvider);
          final canSubmit = _formValid && selectedOrg != null && !_submitting;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              onChanged: () {
                setState(() {
                  _formValid = _formKey.currentState?.validate() ?? false;
                });
              },
              child: ListView(
                children: [
                  _buildOrgField(orgsAsync),
                  DropdownButtonFormField<int>(
                    value: sportId,
                    items: sports
                        .map<DropdownMenuItem<int>>((e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => sportId = v),
                    decoration: InputDecoration(
                      labelText: 'Sport',
                      errorText: fieldErrors['sport'],
                    ),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  DropdownButtonFormField<int>(
                    value: disciplineId,
                    items: categories
                        .map<DropdownMenuItem<int>>((e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => disciplineId = v),
                    decoration: InputDecoration(
                      labelText: 'Discipline',
                      errorText: fieldErrors['discipline'],
                    ),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  DropdownButtonFormField<int?>(
                    value: variantId,
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('None')),
                      ...variants
                          .where((v) => disciplineId == null || v.discipline == disciplineId)
                          .map<DropdownMenuItem<int?>>((e) => DropdownMenuItem<int?>(
                                value: e.id,
                                child: Text(e.name),
                              ))
                          .toList(),
                    ],
                    onChanged: (v) => setState(() => variantId = v),
                    decoration: InputDecoration(
                      labelText: 'Variant',
                      errorText: fieldErrors['variant'],
                    ),
                  ),
                  TextFormField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      errorText: fieldErrors['title'],
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: descCtrl,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      errorText: fieldErrors['description'],
                    ),
                    maxLines: 3,
                  ),
                  DropdownButtonFormField<int>(
                    value: difficulty,
                    decoration: InputDecoration(
                      labelText: 'Difficulty',
                      errorText: fieldErrors['difficulty'],
                    ),
                    items: List.generate(
                      5,
                      (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                    ),
                    onChanged: (v) => setState(() => difficulty = v ?? 1),
                  ),
                  TextFormField(
                    controller: durationCtrl,
                    decoration: InputDecoration(
                      labelText: 'Duration (min)',
                      errorText: fieldErrors['duration'],
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => int.tryParse(v ?? '') == null ? 'Enter number' : null,
                  ),
                  TextFormField(
                    controller: priceCtrl,
                    decoration: InputDecoration(
                      labelText: 'Base Price',
                      errorText: fieldErrors['base_price'],
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => double.tryParse(v ?? '') == null ? 'Enter number' : null,
                  ),
                  _imagePickerField(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: canSubmit ? _submit : null,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(widget.activity == null ? 'Create' : 'Save'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    fieldErrors = {};
    if (!_formKey.currentState!.validate()) return;
    final orgId = ref.read(selectedOrgProvider);
    if (orgId == null) {
      setState(() {
        fieldErrors['organization'] = 'Required';
      });
      return;
    }
    setState(() => _submitting = true);
    try {
      if (widget.activity == null) {
        await widget.service.createActivity(
          sportId!,
          disciplineId!,
          variantId,
          titleCtrl.text.trim(),
          descCtrl.text.trim(),
          difficulty,
          int.parse(durationCtrl.text),
          double.parse(priceCtrl.text),
          organizationId: orgId,
          imageFile: _imageFile,
        );
      } else {
        await widget.service.updateActivity(
          widget.activity!.id,
          sportId!,
          disciplineId!,
          variantId,
          titleCtrl.text.trim(),
          descCtrl.text.trim(),
          difficulty,
          int.parse(durationCtrl.text),
          double.parse(priceCtrl.text),
          organizationId: orgId,
          imageFile: _imageFile,
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                widget.activity == null ? 'Activity created' : 'Activity updated'),
          ),
        );
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      final err = e.error;
      if (err is Map<String, List<String>>) {
        setState(() {
          fieldErrors = err.map((k, v) => MapEntry(k, v.join(', ')));
        });
      } else if (e.response?.statusCode == 403) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'You need a provider account to create activities.')));
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ProviderRegistrationPage()),
          );
        }
      } else if (context.mounted) {
        showApiError(
            context,
            e,
            widget.activity == null
                ? 'Create activity'
                : 'Update activity');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.activity == null
                ? 'Create activity failed: $e'
                : 'Update activity failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildOrgField(AsyncValue<List<Map<String, dynamic>>> orgsAsync) {
    return orgsAsync.when(
      data: (orgs) {
        final selectedOrg = ref.watch(selectedOrgProvider);
        if (orgs.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 8),
                    const Expanded(
                        child:
                            Text('No organisations found. Become a provider first.')),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProviderRegistrationPage()),
                  );
                  ref.invalidate(orgsProvider);
                },
                child: const Text('Become a Provider'),
              ),
            ],
          );
        }
        if (orgs.length == 1) {
          Future.microtask(() {
            if (ref.read(selectedOrgProvider) == null) {
              ref.read(selectedOrgProvider.notifier).state =
                  orgs.first['id'] as int;
            }
          });
          return const SizedBox.shrink();
        }
        return DropdownButtonFormField<int>(
          value: selectedOrg,
          items: orgs
              .map<DropdownMenuItem<int>>((e) => DropdownMenuItem(
                    value: e['id'] as int,
                    child: Text(e['name']?.toString() ?? ''),
                  ))
              .toList(),
          onChanged: (v) => ref.read(selectedOrgProvider.notifier).state = v,
          decoration: InputDecoration(
            labelText: 'Organization',
            errorText: fieldErrors['organization'],
          ),
          validator: (v) => v == null ? 'Required' : null,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _imagePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Image', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildImagePreview(),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () async {
                final picker = ImagePicker();
                final file =
                    await picker.pickImage(source: ImageSource.gallery);
                if (file != null) {
                  setState(() {
                    _imageFile = file;
                    _existingImage = null;
                  });
                }
              },
              child:
                  Text(_imageFile == null ? 'Select Image' : 'Change Image'),
            ),
          ],
        ),
        if (fieldErrors['image'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              fieldErrors['image']!,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePreview() {
    const double size = 80;
    final radius = BorderRadius.circular(12);
    if (_imageFile != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: radius,
            child: Image.file(File(_imageFile!.path),
                width: size, height: size, fit: BoxFit.cover),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: InkWell(
              onTap: () => setState(() => _imageFile = null),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }
    if (_existingImage != null && _existingImage!.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(_existingImage!,
            width: size, height: size, fit: BoxFit.cover),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: radius,
      ),
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }
}
