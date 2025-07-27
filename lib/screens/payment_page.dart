import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/slot.dart';
import '../services/booking_service.dart';
import '../services/payment_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
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
    if (Stripe.publishableKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stripe key missing')),
      );
      return;
    }

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
      final bookings = await bookingService.fetchMine();
      final booking = bookings.firstWhere(
        (b) => b.slot.id == widget.slot.id,
        orElse: () => bookings.first,
      );
      ref.invalidate(bookingsProvider);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmationPage(booking: booking),
        ),
      );
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? e.response?.data['detail']?.toString()
          : null;
      final msg = detail ?? 'HTTP ${e.response?.statusCode ?? ''}: ${e.message}';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } on PlatformException catch (e) {
      if (e.code == FailureCode.Canceled) {
        // user dismissed sheet
      } else if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${e.code}: ${e.message}')));
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
