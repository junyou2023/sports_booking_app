import 'package:flutter/material.dart';
import '../models/slot.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../services/payment_service.dart';
import 'booking_confirmation_page.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key, required this.slot});
  final Slot slot;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool loading = false;

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
              onPressed: loading ? null : _pay,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Pay & Book'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pay() async {
    setState(() => loading = true);
    try {
      final session = await paymentService.createSession(widget.slot.id);
      final clientSecret = session['client_secret'] as String;
      final intentId = session['intent_id'] as String;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Sports Booking',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      final booking = await paymentService.confirmSession(intentId);
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
