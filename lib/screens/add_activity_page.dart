import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../services/activity_service.dart';
import '../services/sports_service.dart';
import '../services/organization_service.dart';
import '../utils/snackbar.dart';

import '../models/activity.dart';
import '../models/sport.dart';
import '../models/category.dart';
import '../models/variant.dart';
import '../models/organization.dart';

class AddActivityPage extends StatefulWidget {
  final Activity? activity;
  const AddActivityPage({this.activity, super.key});

  @override
  State<AddActivityPage> createState() => _AddActivityPageState();
}

class _AddActivityPageState extends State<AddActivityPage> {
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

  late Future<void> _loadFuture;
  List<Sport> sports = [];
  List<Category> categories = [];
  List<Variant> variants = [];
  List<Organization> organizations = [];
  int? organizationId;
  XFile? _imageFile;
  String? _imageUrl;

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
      organizationId = a.organization;
      _imageUrl = a.imageUrl;
    }
    _loadFuture = _loadData();
  }

  Future<void> _loadData() async {
    sports = await sportsService.fetchSports();
    categories = await sportsService.fetchCategories();
    variants = await sportsService.fetchVariants();
    organizations = await organizationService.fetchMine();
    if (organizationId == null && organizations.isNotEmpty) {
      organizationId = organizations.first.id;
    }
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
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  DropdownButtonFormField<int>(
                    value: organizationId,
                    items: organizations
                        .map<DropdownMenuItem<int>>(
                            (e) => DropdownMenuItem(value: e.id, child: Text(e.name)))
                        .toList(),
                    onChanged: (v) => setState(() => organizationId = v),
                    decoration: const InputDecoration(labelText: 'Organization'),
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
                    decoration: const InputDecoration(labelText: 'Sport'),
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
                    decoration: const InputDecoration(labelText: 'Discipline'),
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
                    decoration: const InputDecoration(labelText: 'Variant'),
                  ),
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  DropdownButtonFormField<int>(
                    value: difficulty,
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                    items: List.generate(
                      5,
                      (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                    ),
                    onChanged: (v) => setState(() => difficulty = v ?? 1),
                  ),
                  TextFormField(
                    controller: durationCtrl,
                    decoration: const InputDecoration(labelText: 'Duration (min)'),
                    keyboardType: TextInputType.number,
                    validator: (v) => int.tryParse(v ?? '') == null ? 'Enter number' : null,
                  ),
                  TextFormField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(labelText: 'Base Price'),
                    keyboardType: TextInputType.number,
                    validator: (v) => double.tryParse(v ?? '') == null ? 'Enter number' : null,
                  ),
                  const SizedBox(height: 10),
                  Text('Image', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _imageFile != null
                          ? Image.file(File(_imageFile!.path), width: 100, height: 100, fit: BoxFit.cover)
                          : (_imageUrl != null && _imageUrl!.isNotEmpty)
                              ? Image.network(_imageUrl!, width: 100, height: 100, fit: BoxFit.cover)
                              : Container(width: 100, height: 100, color: Colors.grey[300]),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () async {
                          final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                          if (picked != null) {
                            setState(() {
                              _imageFile = picked;
                              _imageUrl = null;
                            });
                          }
                        },
                        child: const Text('Choose Image'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitting
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            setState(() => _submitting = true);
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
                                  organizationId!,
                                  image: _imageFile,
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
                                  organizationId!,
                                  image: _imageFile,
                                );
                              }
                              if (context.mounted) {
                                Navigator.pop(context, true);
                              }
                            } on DioException catch (e) {
                              if (context.mounted) showApiError(context, e, 'Create activity');
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
