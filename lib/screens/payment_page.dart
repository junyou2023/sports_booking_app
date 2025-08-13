import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/slot.dart';
import '../services/payment_service.dart';
import '../services/slot_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../providers.dart';
import 'booking_confirmation_page.dart';

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key, required this.slot});
  final Slot slot;

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  bool loading = false;
  bool _isMySlot = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkOwnership();
  }

  Future<void> _checkOwnership() async {
    try {
      final mine = await slotService.fetchMerchantSlot(widget.slot.id);
      if (mounted) {
        setState(() {
          _isMySlot = mine != null;
          _checking = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider);
    final alreadyBooked = bookingsAsync.maybeWhen(
      data: (list) => list.any((b) => b.slot.id == widget.slot.id),
      orElse: () => false,
    );
    final slotFull = widget.slot.seatsLeft <= 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.slot.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            if (_checking || bookingsAsync.isLoading)
              const CircularProgressIndicator()
            else ...[
              if (_isMySlot)
                const Text('You cannot book your own slot.')
              else
                ElevatedButton(
                  onPressed:
                      loading || alreadyBooked || slotFull ? null : _pay,
                  child: loading
                      ? const CircularProgressIndicator()
                      : alreadyBooked || slotFull
                          ? const Text('Already booked')
                          : const Text('Pay & Book'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pay() async {
    setState(() => loading = true);
    try {
      final data = await paymentService.createIntent(widget.slot.id);
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: data['client_secret'] as String,
          merchantDisplayName: 'PlayNexus',
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      await Future.delayed(const Duration(seconds: 2));
      final booking = await paymentService.confirmIntent(
        data['payment_intent_id'] as String,
      );
      ref.invalidate(bookingsProvider);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmationPage(booking: booking),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
