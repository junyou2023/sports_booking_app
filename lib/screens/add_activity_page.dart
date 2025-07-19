import 'package:flutter/material.dart';
import '../services/activity_service.dart';
import '../services/sports_service.dart';
import '../utils/snackbar.dart';
import 'package:dio/dio.dart';

import '../models/activity.dart';

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
  final imageCtrl = TextEditingController();

  int? sportId;
  int? disciplineId;
  int? variantId;
  int difficulty = 1;
  bool _submitting = false;

  late Future<void> _loadFuture;
  List<dynamic> sports = [];
  List<dynamic> categories = [];
  List<dynamic> variants = [];

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
      imageCtrl.text = a.image;
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
    imageCtrl.dispose();
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
                  TextFormField(
                    controller: imageCtrl,
                    decoration: const InputDecoration(labelText: 'Image URL'),
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
                                  imageCtrl.text,
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
                                  imageCtrl.text,
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
