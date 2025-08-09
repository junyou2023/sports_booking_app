import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/profile.dart';
import '../providers.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../models/booking.dart';
import '../widgets/auth_sheet.dart';
import 'provider_dashboard_page.dart';
import 'provider_facilities_page.dart';
import 'provider_categories_page.dart';
import 'home_page.dart';

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
        // BUG: token read failure left page stuck on spinner
        // FIX: show guest view when token missing or error (covers: 未登录 token读取失败)
        if (snapshot.hasError || snapshot.data == null) {
          return const _GuestProfile();
        }
        return const _ProfileBody();
      },
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({super.key});

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  late Future<List<Object>> _load;

  @override
  void initState() {
    super.initState();
    _load = Future.wait([
      profileService.fetch(),
      bookingService.fetchMine(),
    ], eagerError: true);
  }

  void _retry() {
    setState(() {
      _load = Future.wait([
        profileService.fetch(),
        bookingService.fetchMine(),
      ], eagerError: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<List<Object>>(
        future: _load,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // BUG: Future.wait fail-fast with no error branch -> infinite spinner
          // FIX: surface error with retry button (covers: 任一接口网络错误/超时)
          if (snapshot.hasError) {
            return _ErrorView(
              title: '加载失败',
              message: '无法获取个人信息或订单。请检查网络，或重新登录后重试。',
              onRetry: _retry,
            );
          }
          final profile = snapshot.data![0] as Profile;
          final bookings = snapshot.data![1] as List<Booking>;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${profile.email}'),
                Text('Company: ${profile.companyName}'),
                Text('Phone: ${profile.phone}'),
                if (profile.isProvider) ...[
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProviderDashboardPage()),
                      );
                    },
                    child: const Text('Provider Dashboard'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProviderFacilitiesPage()),
                      );
                    },
                    child: const Text('My Facilities'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProviderCategoriesPage()),
                      );
                    },
                    child: const Text('Categories'),
                  ),
                ],
                const SizedBox(height: 20),
                Text('My bookings:', style: Theme.of(context).textTheme.titleMedium),
                ...bookings.map((b) => Text(b.slot.title)),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomePage()),
                        (route) => false,
                      );
                    }
                  },
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
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
