import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'registration_page.dart';
import 'package:dio/dio.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref
                      .read(authNotifierProvider.notifier)
                      .login(emailCtrl.text, passCtrl.text);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged in')),
                    );
                    Navigator.of(context).pop();
                  }
                } on DioException catch (e) {
                  if (context.mounted) {
                    final msg = e.response?.data.toString() ?? e.message;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Login failed: ' + msg)),
                    );
                  }
                }
              },
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegistrationPage()),
                );
              },
              child: const Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }
}
