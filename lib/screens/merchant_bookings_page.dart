import 'package:flutter/material.dart';

class MerchantBookingsPage extends StatelessWidget {
  const MerchantBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppBar(title: Text('Merchant Bookings')),
      body: Center(child: Text('No bookings yet')),
    );
  }
}
