import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/slot.dart';
import '../services/booking_service.dart';
import '../services/payment_service.dart';
import '../services/slot_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../providers.dart';
import 'booking_confirmation_page.dart';
import 'package:dio/dio.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.slot.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            if (_checking)
              const CircularProgressIndicator()
            else ...[
              if (_isMySlot)
                const Text('You cannot book your own slot.')
              else
                ElevatedButton(
                  onPressed: loading ? null : _pay,
                  child: loading
                      ? const CircularProgressIndicator()
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
      final clientSecret = data['client_secret'] as String?;
      final intentId = data['payment_intent_id'] as String?;
      if (clientSecret == null || intentId == null) {
        throw Exception('Invalid payment response');
      }
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'PlayNexus',
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      await Future.delayed(const Duration(seconds: 2));
      final booking = await paymentService.confirmIntent(intentId);
      ref.invalidate(bookingsProvider);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmationPage(booking: booking),
        ),
      );
    } on DioException catch (e) {
      String msg;
      final data = e.response?.data;
      if (data is Map && data['detail'] != null) {
        msg = data['detail'].toString();
        if (msg == 'cannot_book_own_slot') {
          msg = 'You cannot book your own slot.';
        }
      } else {
        msg = e.message ?? 'Payment failed';
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
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
