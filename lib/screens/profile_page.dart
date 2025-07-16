import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/profile.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../models/booking.dart';
import '../widgets/auth_sheet.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String?>(
      future: authService.getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data == null) {
          return const _GuestProfile();
        }
        return _ProfileBody();
      },
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<List<Object>>(
        future: Future.wait([
          profileService.fetch(),
          bookingService.fetchMine(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snapshot.data![0] as Profile;
          final bookings = snapshot.data![1] as List<Booking>;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: \${profile.email}'),
                Text('Company: \${profile.companyName}'),
                Text('Phone: \${profile.phone}'),
                const SizedBox(height: 20),
                Text('My bookings:', style: Theme.of(context).textTheme.titleMedium),
                ...bookings.map((b) => Text(b.slot.title)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GuestProfile extends StatelessWidget {
  const _GuestProfile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text('Access your bookings from any device'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => showAuthSheet(context),
              child: const Text('Log in or sign up'),
            ),
          ],
        ),
      ),
    );
  }
}
