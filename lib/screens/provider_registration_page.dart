import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../utils/snackbar.dart';
import 'profile_page.dart';
import 'package:dio/dio.dart';

class ProviderRegistrationPage extends ConsumerStatefulWidget {
  const ProviderRegistrationPage({super.key});

  @override
  ConsumerState<ProviderRegistrationPage> createState() => _ProviderRegistrationPageState();
}

class _ProviderRegistrationPageState
    extends ConsumerState<ProviderRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final pass2Ctrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  bool _loading = false;
  
  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    pass2Ctrl.dispose();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Signup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      v != null && v.contains('@') ? null : 'Enter a valid email',
                ),
                TextFormField(
                  controller: passCtrl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) =>
                      v != null && v.length >= 6 ? null : 'Password too short',
                ),
                TextFormField(
                  controller: pass2Ctrl,
                  decoration:
                      const InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                  validator: (v) =>
                      v == passCtrl.text ? null : 'Passwords do not match',
                ),
                TextFormField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Organisation name'),
                ),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                TextFormField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Address'),
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
                              await ref
                                  .read(authNotifierProvider.notifier)
                                  .registerProvider(
                                    emailCtrl.text,
                                    passCtrl.text,
                                    pass2Ctrl.text,
                                    nameCtrl.text,
                                    phoneCtrl.text,
                                    addressCtrl.text,
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Provider account created.')),
                                );
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (_) => const ProfilePage()),
                                );
                              }
                            } on DioException catch (e) {
                              if (context.mounted) {
                                showApiError(context, e, 'Registration');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Registration failed: $e')),
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
                        : const Text('Create provider account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
