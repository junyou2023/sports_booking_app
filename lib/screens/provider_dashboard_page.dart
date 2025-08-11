// lib/screens/provider_dashboard_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../models/activity.dart';
import '../services/activity_service.dart';
import '../services/slot_service.dart';

import 'add_activity_page.dart';
import 'add_slot_page.dart';
import 'add_facility_page.dart';
import 'merchant_slots_page.dart';
import 'merchant_bookings_page.dart';
import 'provider_facilities_page.dart';
import 'provider_categories_page.dart';
import 'edit_sport_page.dart';

class ProviderDashboardPage extends ConsumerStatefulWidget {
  const ProviderDashboardPage({super.key});

  @override
  ConsumerState<ProviderDashboardPage> createState() => _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends ConsumerState<ProviderDashboardPage> {
  final List<Activity> _activities = [];
  String? _next;
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final page = await activityService.fetchActivities(params: {'mine': '1'});
      setState(() {
        _activities
          ..clear()
          ..addAll(page.results);
        _next = page.next;
        _page = 1;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_next == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final page =
          await activityService.fetchActivities(params: {'mine': '1', 'page': nextPage});
      setState(() {
        _activities.addAll(page.results);
        _next = page.next;
        _page = nextPage;
      });
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        appBar: AppBar(title: Text('Merchant Dashboard')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _MerchantDrawer(),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _AddActivityHero(onTap: () async {
              final result = await Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const AddActivityPage()));
              if (result is Activity) {
                setState(() => _activities.insert(0, result));
                unawaited(_refresh());
              }
            }),
            const SizedBox(height: 16),
            _QuickLinkCard(
              label: 'Create Sport',
              icon: Icons.sports_martial_arts_outlined,
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const EditSportPage())),
            ),
            const SizedBox(height: 16),
            _QuickLinkCard(
              label: 'Add Facility',
              icon: Icons.store_mall_directory_outlined,
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const AddFacilityPage())),
            ),
            const SizedBox(height: 16),
            _QuickLinkCard(
              label: 'Manage Slots',
              icon: Icons.schedule,
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const MerchantSlotsPage())),
            ),
            const SizedBox(height: 16),
            _QuickLinkCard(
              label: 'Merchant Bookings',
              icon: Icons.event_note,
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const MerchantBookingsPage())),
            ),
            const SizedBox(height: 16),
            Text('Your Activities', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_activities.isEmpty)
              _EmptyState(onCreate: () async {
                final result = await Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const AddActivityPage()));
                if (result is Activity) {
                  setState(() => _activities.insert(0, result));
                  unawaited(_refresh());
                }
              })
            else
              ..._activities.map(
                (a) => _ActivityCard(activity: a, onChanged: () => _refresh()),
              ),
            if (_loadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_next != null)
              TextButton(onPressed: _loadMore, child: const Text('Load more')),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _MerchantDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Center(child: Text('Merchant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
            ),
            ListTile(
              leading: const Icon(Icons.store_mall_directory_outlined),
              title: const Text('Facilities'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProviderFacilitiesPage())),
            ),
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Categories'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProviderCategoriesPage())),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddActivityHero extends StatelessWidget {
  const _AddActivityHero({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).dividerColor)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          height: 88,
          child: Row(
            children: [
              const SizedBox(width: 16),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text('Add Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickLinkCard extends StatelessWidget {
  const _QuickLinkCard({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          height: 88,
          child: Row(
            children: [
              const SizedBox(width: 16),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(label,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No activities yet'),
              const SizedBox(height: 8),
              TextButton(onPressed: onCreate, child: const Text('Create Activity')),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, required this.onChanged});
  final Activity activity;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).dividerColor)),
      child: ListTile(
        leading: _ActivityThumb(imageUrl: activity.imageUrl?.isNotEmpty == true ? activity.imageUrl! : activity.image),
        title: Text(activity.title),
        subtitle: FutureBuilder<int>(
          future: _upcomingSlotsCount(activity.id),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Text('…');
            }
            final c = snap.data ?? 0;
            return Text(c == 0 ? 'No upcoming slots' : '$c upcoming slot${c == 1 ? "" : "s"}');
          },
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              icon: const Icon(Icons.schedule),
              tooltip: 'Add Slot',
              onPressed: () async {
                final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddSlotPage(activityId: activity.id)));
                if (created == true) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Slot created')));
                  onChanged();
                }
              },
            ),
            TextButton(
              onPressed: () async {
                final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AddActivityPage(activity: activity)));
                if (updated is Activity) onChanged();
              },
              child: const Text('Edit'),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Delete ${activity.title}?'),
                      content: const Text('This action cannot be undone.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel')),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await activityService.deleteActivity(activity.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Activity deleted')));
                      }
                      onChanged();
                    } on DioException catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.message ?? 'Delete failed')));
                    }
                  }
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<int> _upcomingSlotsCount(int activityId) async {
    try {
      final slots = await slotService.fetchByActivity(activityId);
      return slots.length;
    } catch (_) {
      return 0;
    }
  }
}

class _ActivityThumb extends StatelessWidget {
  const _ActivityThumb({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.image_not_supported_outlined),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover),
    );
  }
}
