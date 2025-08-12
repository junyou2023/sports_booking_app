import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/slot.dart';
import '../services/booking_service.dart';
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
  bool _isMine = false;

  @override
  void initState() {
    super.initState();
    _checkOwn();
  }

  Future<void> _checkOwn() async {
    final profile = await ref.read(profileProvider.future);
    if (profile.isProvider) {
      final mine = await slotService.isMine(widget.slot.id);
      if (mounted) setState(() => _isMine = mine);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.slot.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading || _isMine ? null : _pay,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Pay & Book'),
            ),
            if (_isMine)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('商家不能预订自己的场次'),
              ),
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
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
