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
  final _nameCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
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
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _loading = true);
                        try {
                          await sportsService.createSport(_nameCtrl.text.trim());
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Sport created')));
                            Navigator.pop(context, true);
                          }
                        } on DioException catch (e) {
                          if (e.response?.statusCode == 401 ||
                              e.response?.statusCode == 403) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Permission denied (contact admin)')));
                            }
                          } else if (context.mounted) {
                            showApiError(context, e, 'Create sport');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Create sport failed: $e')),
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
              )
            ],
          ),
        ),
      ),
    );
  }
}
