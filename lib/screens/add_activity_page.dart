import 'dart:io'; // R1
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // R1 requires `flutter pub add image_picker` (iOS: NSPhotoLibraryUsageDescription, Android: storage permission)
import '../services/activity_service.dart';
import '../services/sports_service.dart';
import '../utils/snackbar.dart';
import 'package:dio/dio.dart';

import '../models/activity.dart';
import '../models/sport.dart';
import '../models/category.dart';
import '../models/variant.dart';

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
  XFile? _image; // R1

  int? sportId;
  int? disciplineId;
  int? variantId;
  int difficulty = 1;
  bool _submitting = false;

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
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
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
                  const SizedBox(height: 12), // R1
                  if (_image != null) ...[ // R1
                    ClipRRect( // R1
                      borderRadius: BorderRadius.circular(8), // R1
                      child: Image.file( // R1
                        File(_image!.path), // R1
                        height: 150, // R1
                        width: 150, // R1
                        fit: BoxFit.cover, // R1
                      ),
                    ),
                    TextButton( // R1
                      onPressed: () => setState(() => _image = null), // R1
                      child: const Text('Remove'), // R1
                    ),
                  ],
                  TextButton.icon( // R1
                    onPressed: () async { // R1
                      final img = await ImagePicker().pickImage(source: ImageSource.gallery); // R1
                      if (img != null) setState(() => _image = img); // R1
                    },
                    icon: const Icon(Icons.image), // R1
                    label: Text(_image == null ? 'Pick Image' : 'Change Image'), // R1
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
                                  imagePath: _image?.path, // R1
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
                                  imagePath: _image?.path, // R1
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
