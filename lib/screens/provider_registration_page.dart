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

class _ProviderRegistrationPageState extends ConsumerState<ProviderRegistrationPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final pass2Ctrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

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
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              TextField(controller: pass2Ctrl, decoration: const InputDecoration(labelText: 'Confirm Password'), obscureText: true),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Organisation name')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await ref.read(authNotifierProvider.notifier).registerProvider(
                          emailCtrl.text,
                          passCtrl.text,
                          pass2Ctrl.text,
                          nameCtrl.text,
                          phoneCtrl.text,
                          addressCtrl.text,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Provider account created.')), 
                      );
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                    }
                  } on DioException catch (e) {
                    if (context.mounted) {
                      showApiError(context, e, 'Registration');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Registration failed: $e')),
                      );
                    }
                  }
                },
                child: const Text('Create provider account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
