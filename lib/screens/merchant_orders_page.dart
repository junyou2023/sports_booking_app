import 'package:flutter/material.dart';
import '../services/merchant_booking_service.dart';
import '../utils/snackbar.dart';

class MerchantOrdersPage extends StatefulWidget { // R2
  const MerchantOrdersPage({super.key}); // R2

  @override
  State<MerchantOrdersPage> createState() => _MerchantOrdersPageState(); // R2
}

class _MerchantOrdersPageState extends State<MerchantOrdersPage> { // R2
  final ScrollController _scroll = ScrollController();
  final List<Map<String, dynamic>> _orders = []; // R2
  String? _cursor; // R2
  bool _loading = false; // R2
  String? _status; // R2
  bool? _paid; // R2

  @override
  void initState() {
    super.initState();
    _load(true);
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 && !_loading && _cursor != null) {
        _load(false);
      }
    });
  }

  Future<void> _load(bool refresh) async { // R2
    if (_loading) return;
    setState(() => _loading = true);
    if (refresh) {
      _cursor = null;
      _orders.clear();
    }
    final data = await merchantBookingService.fetchPaged(cursor: _cursor, status: _status, paid: _paid); // R2
    _cursor = data['next'] as String?;
    final List list = data['results'] as List? ?? [];
    _orders.addAll(list.cast<Map<String, dynamic>>());
    setState(() => _loading = false);
  }

  Future<void> _cancel(int id) async { // R2
    try {
      await merchantBookingService.cancel(id);
      showSnackBar(context, 'Cancelled');
      await _load(true);
    } catch (e) {
      showSnackBar(context, 'Failed: $e');
    }
  }

  void _setStatus(String? s) async { // R2
    _status = s;
    await _load(true);
  }

  void _setPaid(bool? p) async { // R2
    _paid = p;
    await _load(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')), // R2
      body: Column(
        children: [
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _status == null,
                onSelected: (_) => _setStatus(null),
              ),
              for (final s in ['pending', 'confirmed', 'cancelled', 'refunded', 'completed'])
                ChoiceChip(label: Text(s), selected: _status == s, onSelected: (_) => _setStatus(s)),
              const SizedBox(width: 16),
              FilterChip(
                label: const Text('Paid'),
                selected: _paid == true,
                onSelected: (_) => _setPaid(_paid == true ? null : true),
              ),
              FilterChip(
                label: const Text('Unpaid'),
                selected: _paid == false,
                onSelected: (_) => _setPaid(_paid == false ? null : false),
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(true),
              child: ListView.builder(
                controller: _scroll,
                itemCount: _orders.length + 1,
                itemBuilder: (context, i) {
                  if (i >= _orders.length) {
                    return _cursor == null
                        ? const SizedBox(height: 80)
                        : const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                  }
                  final o = _orders[i];
                  final id = o['id'] as int;
                  final status = o['status'] as String? ?? '';
                  final paid = o['paid'] as bool? ?? false;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text('Order #$id'),
                      subtitle: Text('$status - ${paid ? 'paid' : 'unpaid'}'),
                      trailing: status == 'cancelled'
                          ? null
                          : TextButton(
                              onPressed: () => _cancel(id),
                              child: const Text('Cancel'),
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
