import 'package:flutter/material.dart';
import '../models/slot.dart';
import '../services/slot_service.dart';

class MerchantSlotsPage extends StatefulWidget {
  const MerchantSlotsPage({super.key});

  @override
  State<MerchantSlotsPage> createState() => _MerchantSlotsPageState();
}

class _MerchantSlotsPageState extends State<MerchantSlotsPage> {
  final List<Slot> _slots = [];
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
      final page = await slotService.fetchMine(page: 1);
      setState(() {
        _slots
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
      final page = await slotService.fetchMine(page: nextPage);
      setState(() {
        _slots.addAll(page.results);
        _next = page.next;
        _page = nextPage;
      });
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Slots')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                itemCount: _slots.length + 1,
                itemBuilder: (context, index) {
                  if (index == _slots.length) {
                    if (_loadingMore) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else if (_next != null) {
                      _loadMore();
                      return const SizedBox();
                    } else {
                      return const SizedBox(height: 80);
                    }
                  }
                  final s = _slots[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(s.title),
                      subtitle: Text(
                          '${s.beginsAt.toLocal()} - ${s.endsAt.toLocal()}'),
                      trailing: Text(s.price.toStringAsFixed(2)),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
