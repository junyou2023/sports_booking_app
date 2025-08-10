// lib/screens/provider_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity.dart';
import '../services/activity_service.dart'; // R2
import '../services/slot_service.dart';

import 'add_activity_page.dart';
import 'add_slot_page.dart';
import 'merchant_slots_page.dart'; // R2
import 'merchant_orders_page.dart'; // R2
import 'provider_facilities_page.dart';
import 'provider_categories_page.dart';

class ProviderDashboardPage extends ConsumerStatefulWidget { // R2
  const ProviderDashboardPage({super.key});

  @override
  ConsumerState<ProviderDashboardPage> createState() => _ProviderDashboardPageState(); // R2
}

class _ProviderDashboardPageState extends ConsumerState<ProviderDashboardPage> { // R2
  final ScrollController _scroll = ScrollController(); // R2
  final List<Activity> _activities = []; // R2
  bool _loading = false; // R2
  bool _hasMore = true; // R2
  int _page = 1; // R2
  String? _q; // R2
  int? _category; // R2

  @override
  void initState() {
    super.initState();
    _load(refresh: true); // R2
    _scroll.addListener(() { // R2
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 && _hasMore && !_loading) {
        _load();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async { // R2
    if (_loading) return;
    setState(() => _loading = true);
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _activities.clear();
    }
    final page = await activityService.fetchMine(q: _q, category: _category, page: _page); // R2
    _activities.addAll(page.results); // R2
    _hasMore = page.next != null; // R2
    _page += 1; // R2
    setState(() => _loading = false);
  }

  Future<void> _showFilterSheet() async { // R2
    final qCtrl = TextEditingController(text: _q);
    int? selectedCat = _category;
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: qCtrl, decoration: const InputDecoration(labelText: 'Keyword')), // R2
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Category ID'), // R2
                keyboardType: TextInputType.number,
                onChanged: (v) => selectedCat = int.tryParse(v),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        );
      },
    );
    _q = qCtrl.text.isEmpty ? null : qCtrl.text;
    _category = selectedCat;
    await _load(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long), // R2
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MerchantOrdersPage())), // R2
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showFilterSheet, // R2
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _MerchantDrawer(),
      body: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.all(16),
          itemCount: _activities.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _AddActivityHero(onTap: () async {
                final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddActivityPage()));
                if (created == true) await _load(refresh: true);
              });
            }
            if (index == 1) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text('Your Activities', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                ],
              );
            }
            final i = index - 2;
            if (i >= _activities.length) {
              return _hasMore
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : const SizedBox(height: 80);
            }
            final a = _activities[i];
            return _ActivityCard(activity: a, onChanged: () => _load(refresh: true));
          },
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
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MerchantSlotsPage(activityId: activity.id))), // R2
        trailing: PopupMenuButton<String>( // R2
          onSelected: (value) async { // R2
            if (value == 'edit') {
              final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddActivityPage(activity: activity))); // R2
              if (updated == true) onChanged(); // R2
            } else if (value == 'slot') {
              final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddSlotPage(activityId: activity.id))); // R2
              if (created == true) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Slot created'))); // R2
                onChanged(); // R2
              }
            } else if (value == 'delete') {
              final ok = await showDialog<bool>( // R2
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Activity?'),
                  content: const Text('This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (ok == true) {
                await activityService.deleteActivity(activity.id); // R2
                onChanged(); // R2
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')), // R2
            const PopupMenuItem(value: 'slot', child: Text('Add Slot')), // R2
            const PopupMenuItem(value: 'delete', child: Text('Delete')), // R2
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
