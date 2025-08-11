import 'package:flutter/material.dart';

class MerchantBookingsPage extends StatelessWidget {
  const MerchantBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Merchant Bookings')),
      body: const Center(child: Text('No bookings yet')),
    );
  }
}
