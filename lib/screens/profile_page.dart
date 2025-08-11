import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/profile.dart';
import '../models/booking.dart';

import '../services/profile_service.dart';
import '../services/booking_service.dart';
import '../services/favorite_service.dart';
import '../services/auth_service.dart';

import 'bookings_page.dart';
import 'favorites_page.dart';
import 'provider_dashboard_page.dart';
import 'edit_profile_page.dart';
import 'login_page.dart';
import 'reset_password_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late Future<_ProfileBundle> _load;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  Future<_ProfileBundle> _fetch() async {
    final token = await authService.getToken();
    if (token == null) return _ProfileBundle.guest();

    final profile = await profileService.fetch();
    final bookings = await bookingService.fetchMine();
    final favIds = await favoriteService.fetchFavoriteIds();

    return _ProfileBundle(
      profile: profile,
      bookings: bookings,
      favoritesCount: favIds.length,
    );
  }

  void _retry() => setState(() => _load = _fetch());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProfileBundle>(
      future: _load,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: _ErrorView(
              title: 'Something went wrong',
              message: snap.error.toString(),
              onRetry: _retry,
            ),
          );
        }

        final bundle = snap.data!;
        if (bundle.isGuest) return const _GuestProfile();

        final upcoming = bundle.bookings
            .where((b) => b.slot.beginsAt.isAfter(DateTime.now()))
            .toList()
          ..sort((a, b) => a.slot.beginsAt.compareTo(b.slot.beginsAt));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => _showSettings(context),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async => _retry(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderCard(
                  profile: bundle.profile!,
                  bookingsCount: bundle.bookings.length,
                  favoritesCount: bundle.favoritesCount,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditProfilePage()),
                          );
                          if (updated == true) _retry();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Edit Profile'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showSettings(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Settings'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (bundle.profile!.isProvider) ...[
                  _SectionTitle('Merchant'),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.storefront_outlined),
                      title: const Text('Open Merchant Dashboard'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProviderDashboardPage()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                _SectionTitle('Upcoming'),
                if (upcoming.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No upcoming bookings', style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  )
                else
                  ...upcoming.take(6).map((b) => _BookingTile(booking: b)),
                const SizedBox(height: 8),
                if (upcoming.length > 6)
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BookingsPage()),
                    ),
                    child: const Text('See all'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.favorite_outline),
                  title: const Text('Favorites'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock_reset),
                  title: const Text('Reset Password'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ResetPasswordPage()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Log out'),
                  onTap: () async {
                    Navigator.pop(context);
                    await authService.logout();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out')));
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.profile,
    required this.bookingsCount,
    required this.favoritesCount,
  });

  final Profile profile;
  final int bookingsCount;
  final int favoritesCount;

  @override
  Widget build(BuildContext context) {
    final initials = (profile.companyName.isNotEmpty ? profile.companyName[0] : profile.email[0]).toUpperCase();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _Avatar(initials: initials),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.companyName.isNotEmpty ? profile.companyName : profile.email.split('@').first,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(profile.email, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatChip(label: 'Bookings', value: bookingsCount.toString()),
                      const SizedBox(width: 12),
                      _StatChip(label: 'Favorites', value: favoritesCount.toString()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final from = TimeOfDay.fromDateTime(booking.slot.beginsAt).format(context);
    final to = TimeOfDay.fromDateTime(booking.slot.endsAt).format(context);
    final timeRange = '$from – $to';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const _Thumb(),
        title: Text(booking.slot.title),
        subtitle: Text('$timeRange • ${booking.slot.location}', maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {}, // 与旧版一致：不跳详情，避免潜在空路由
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: const Icon(Icons.sports_soccer_outlined, size: 22),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 32,
      child: Text(initials, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.title, required this.message, required this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _GuestProfile extends StatelessWidget {
  const _GuestProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('You are not logged in'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileBundle {
  final bool isGuest;
  final Profile? profile;
  final List<Booking> bookings;
  final int favoritesCount;

  _ProfileBundle({
    this.isGuest = false,
    this.profile,
    this.bookings = const [],
    this.favoritesCount = 0,
  });

  _ProfileBundle.guest()
      : isGuest = true,
        profile = null,
        bookings = const [],
        favoritesCount = 0;
}
