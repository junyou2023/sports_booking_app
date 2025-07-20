import 'package:flutter/material.dart';
import '../models/sport_category.dart';
import '../services/sport_category_service.dart';

class EditCategoryPage extends StatefulWidget {
  final SportCategory? category;
  final List<SportCategory> all;
  const EditCategoryPage({super.key, required this.all, this.category});

  @override
  State<EditCategoryPage> createState() => _EditCategoryPageState();
}

class _EditCategoryPageState extends State<EditCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  int? parentId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    if (c != null) {
      nameCtrl.text = c.name;
      parentId = c.parent;
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Category' : 'Add Category')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              DropdownButtonFormField<int?>(
                value: parentId,
                decoration: const InputDecoration(labelText: 'Parent'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Root')),
                  ...widget.all
                      .where((e) => widget.category == null || e.id != widget.category!.id)
                      .map((e) => DropdownMenuItem<int?>(
                            value: e.id,
                            child: Text(e.fullPath),
                          ))
                      .toList(),
                ],
                onChanged: (v) => setState(() => parentId = v),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitting
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _submitting = true);
                        try {
                          if (isEditing) {
                            await sportCategoryService.updateCategory(
                                widget.category!.id, nameCtrl.text, parentId);
                          } else {
                            await sportCategoryService.createCategory(
                                nameCtrl.text, parentId);
                          }
                          if (context.mounted) Navigator.pop(context, true);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        } finally {
                          if (mounted) setState(() => _submitting = false);
                        }
                      },
                child: Text(isEditing ? 'Save' : 'Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
