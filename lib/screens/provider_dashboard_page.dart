// lib/screens/provider_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity.dart';
import '../services/activity_service.dart';
import '../services/slot_service.dart';

import 'add_activity_page.dart';
import 'add_slot_page.dart';
import 'provider_facilities_page.dart';
import 'provider_categories_page.dart';

class ProviderDashboardPage extends ConsumerStatefulWidget {
  const ProviderDashboardPage({super.key});

  @override
  ConsumerState<ProviderDashboardPage> createState() => _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends ConsumerState<ProviderDashboardPage> {
  final List<Activity> _activities = [];
  final ScrollController _controller = ScrollController();
  bool _loading = false;
  String? _next;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _refresh();
    _controller.addListener(() {
      if (_controller.position.pixels >=
              _controller.position.maxScrollExtent - 200 &&
          !_loading &&
          _next != null) {
        _loadMore();
      }
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _activities.clear();
      _page = 1;
      _next = null;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final page =
          await activityService.fetchActivities(params: {'mine': '1', 'page': _page});
      setState(() {
        _activities.addAll(page.results);
        _next = page.next;
        if (page.next != null) _page += 1;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {}, // reserved for future search
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {}, // profile quick access
          ),
        ],
      ),
      drawer: _MerchantDrawer(),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _activities.isEmpty && !_loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  const Center(child: Text('暂无活动')),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        final created = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AddActivityPage()));
                        if (created == true) _refresh();
                      },
                      child: const Text('去创建活动'),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                controller: _controller,
                padding: const EdgeInsets.all(16),
                itemCount: _activities.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _AddActivityHero(onTap: () async {
                      final created = await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AddActivityPage()));
                      if (created == true) _refresh();
                    });
                  }
                  index -= 1;
                  if (index < _activities.length) {
                    final a = _activities[index];
                    return _ActivityCard(activity: a, onChanged: _refresh);
                  }
                  return _loading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : const SizedBox(height: 80);
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
                final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddActivityPage(activity: activity)));
                if (updated == true) onChanged();
              },
              child: const Text('Edit'),
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
