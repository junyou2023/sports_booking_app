import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/facility_service.dart';
import '../utils/snackbar.dart';

class AddActivityPage extends StatefulWidget {
  const AddActivityPage({super.key});

  @override
  State<AddActivityPage> createState() => _AddActivityPageState();
}

class _AddActivityPageState extends State<AddActivityPage> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final latCtrl = TextEditingController();
  final lngCtrl = TextEditingController();
  final radiusCtrl = TextEditingController(text: '1000');
  final categoriesCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
    radiusCtrl.dispose();
    categoriesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Activity')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: latCtrl,
                decoration: const InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.number,
                validator: (v) => double.tryParse(v ?? '') == null
                    ? 'Enter a number'
                    : null,
              ),
              TextFormField(
                controller: lngCtrl,
                decoration: const InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.number,
                validator: (v) => double.tryParse(v ?? '') == null
                    ? 'Enter a number'
                    : null,
              ),
              TextFormField(
                controller: radiusCtrl,
                decoration: const InputDecoration(labelText: 'Radius (m)'),
                keyboardType: TextInputType.number,
                validator: (v) => double.tryParse(v ?? '') == null
                    ? 'Enter a number'
                    : null,
              ),
              TextFormField(
                controller: categoriesCtrl,
                decoration: const InputDecoration(
                    labelText: 'Category IDs (comma separated)'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _loading = true);
                          try {
                            final ids = categoriesCtrl.text
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList();
                            await facilityService.createFacility(
                              nameCtrl.text,
                              double.parse(latCtrl.text),
                              double.parse(lngCtrl.text),
                              double.tryParse(radiusCtrl.text) ?? 1000,
                              ids,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Activity added')));
                              Navigator.pop(context, true);
                            }
                          } on DioException catch (e) {
                            if (context.mounted) {
                              showApiError(context, e, 'Create facility');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _loading = false);
                          }
                        },
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
