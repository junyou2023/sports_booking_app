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
import '../utils/snackbar.dart';

class AddActivityPage extends ConsumerStatefulWidget {
  final Activity? activity;
  const AddActivityPage({this.activity, super.key});

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
  int? organizationId;
  bool _submitting = false;
  XFile? _imageFile;
  Map<String, String> fieldErrors = {};

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
      difficulty = a.difficulty;
    }
    _loadFuture = _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      sportsService.fetchSports().then((v) => sports = v),
      sportsService.fetchCategories().then((v) => categories = v),
      sportsService.fetchVariants().then((v) => variants = v),
      ref.read(orgsProvider.notifier).load(),
    ]);
    organizationId = ref.read(orgsProvider.notifier).selectedId;
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
    final orgsAsync = ref.watch(orgsProvider);
    final orgs = orgsAsync.value ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Create Activity')),
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
                  if (orgs.length > 1)
                    DropdownButtonFormField<int>(
                      value: organizationId,
                      items: orgs
                          .map<DropdownMenuItem<int>>((e) => DropdownMenuItem(
                                value: e['id'] as int,
                                child: Text(e['name'].toString()),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() => organizationId = v);
                        if (v != null) {
                          ref.read(orgsProvider.notifier).select(v);
                        }
                      },
                      decoration: InputDecoration(
                          labelText: '组织',
                          errorText: fieldErrors['organization']),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
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
                        labelText: 'Sport', errorText: fieldErrors['sport']),
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
                        errorText: fieldErrors['discipline']),
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
                    decoration: InputDecoration(labelText: 'Variant', errorText: fieldErrors['variant']),
                  ),
                  TextFormField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                        labelText: 'Title', errorText: fieldErrors['title']),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: descCtrl,
                    decoration: InputDecoration(
                        labelText: 'Description', errorText: fieldErrors['description']),
                    maxLines: 3,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  DropdownButtonFormField<int>(
                    value: difficulty,
                    decoration: InputDecoration(
                        labelText: 'Difficulty', errorText: fieldErrors['difficulty']),
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
                        errorText: fieldErrors['duration']),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Enter positive number';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: priceCtrl,
                    decoration: InputDecoration(
                        labelText: 'Base Price', errorText: fieldErrors['base_price']),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Enter number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  if (_imageFile != null)
                    Stack(
                      children: [
                        Image.file(File(_imageFile!.path), height: 150, fit: BoxFit.cover),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _imageFile = null),
                          ),
                        ),
                      ],
                    )
                  else
                    OutlinedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('选择图片'),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final file = await picker.pickImage(source: ImageSource.gallery);
                        if (file != null) setState(() => _imageFile = file);
                      },
                    ),
                  if (fieldErrors['image'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        fieldErrors['image']!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitting
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            setState(() {
                              _submitting = true;
                              fieldErrors = {};
                            });
                            try {
                              if (widget.activity == null) {
                                await activityService.createActivity(
                                  sportId!,
                                  disciplineId!,
                                  variantId,
                                  titleCtrl.text,
                                  descCtrl.text,
                                  difficulty,
                                  int.parse(durationCtrl.text),
                                  double.parse(priceCtrl.text),
                                  organizationId: organizationId!,
                                  imageFile: _imageFile,
                                );
                              } else {
                                await activityService.updateActivity(
                                  widget.activity!.id,
                                  sportId!,
                                  disciplineId!,
                                  variantId,
                                  titleCtrl.text,
                                  descCtrl.text,
                                  difficulty,
                                  int.parse(durationCtrl.text),
                                  double.parse(priceCtrl.text),
                                  organizationId: organizationId!,
                                  imageFile: _imageFile,
                                );
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(content: Text('创建成功')));
                                Navigator.pop(context, true);
                              }
                            } on FieldErrors catch (e) {
                              setState(() {
                                fieldErrors =
                                    e.errors.map((k, v) => MapEntry(k, v.join(', ')));
                              });
                            } on DioException catch (e) {
                              if (context.mounted) {
                                showApiError(context, e, 'Create activity');
                              }
                            } finally {
                              if (mounted) setState(() => _submitting = false);
                            }
                          },
                    child: _submitting
                        ? const SizedBox(height:20,width:20,child:CircularProgressIndicator(strokeWidth:2))
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
}
