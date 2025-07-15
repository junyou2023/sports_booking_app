import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'profile_page.dart';
import 'package:dio/dio.dart';
import '../utils/snackbar.dart';

class RegistrationPage extends ConsumerStatefulWidget {
  const RegistrationPage({super.key});

  @override
  ConsumerState<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends ConsumerState<RegistrationPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final pass2Ctrl = TextEditingController();
  String strength = '';

  @override
  void initState() {
    super.initState();
    passCtrl.addListener(_updateStrength);
  }

  void _updateStrength() {
    final p = passCtrl.text;
    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
    setState(() {
      if (score >= 4) {
        strength = 'Strong';
      } else if (score >= 3) {
        strength = 'Medium';
      } else {
        strength = 'Weak';
      }
    });
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    pass2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Strength: \$strength'),
            ),
            TextField(controller: pass2Ctrl, decoration: const InputDecoration(labelText: 'Confirm Password'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref
                      .read(authNotifierProvider.notifier)
                      .register(emailCtrl.text, passCtrl.text, pass2Ctrl.text);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Registration successful. Check your email to verify your account.')),
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
              child: const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }
}
