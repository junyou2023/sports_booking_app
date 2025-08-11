import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../services/sports_service.dart';
import '../utils/snackbar.dart';

class EditSportPage extends StatefulWidget {
  const EditSportPage({super.key});

  @override
  State<EditSportPage> createState() => _EditSportPageState();
}

class _EditSportPageState extends State<EditSportPage> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Sport')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitting
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _submitting = true);
                        try {
                          await sportsService.createSport(nameCtrl.text.trim());
                          if (mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('Sport created')));
                            Navigator.pop(context, true);
                          }
                        } on DioException catch (e) {
                          if (mounted) {
                            if (e.response?.statusCode == 401 ||
                                e.response?.statusCode == 403) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Permission denied (contact admin)')));
                            } else {
                              showApiError(context, e, 'Create sport');
                            }
                          }
                        } finally {
                          if (mounted) setState(() => _submitting = false);
                        }
                      },
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
