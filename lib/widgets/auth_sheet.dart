import 'package:flutter/material.dart';
import '../screens/login_page.dart';

/// Modal bottom sheet used for login or registration actions.
class AuthSheet extends StatelessWidget {
  const AuthSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final emailCtrl = TextEditingController();
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Google sign-in not implemented')),
              );
            },
            icon: const Icon(Icons.g_mobiledata),
            label: const Text('Continue with Google'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Facebook sign-in not implemented')),
              );
            },
            icon: const Icon(Icons.facebook),
            label: const Text('Continue with Facebook'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
          ),
          const Divider(height: 32),
          TextField(
            controller: emailCtrl,
            decoration: const InputDecoration(labelText: 'Email address'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context); // dismiss sheet
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: const Text('Continue with email'),
          ),
        ],
      ),
    );
  }
}

void showAuthSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const AuthSheet(),
  );
}
