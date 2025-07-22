// lib/models/booking.dart
//
// Local model mirroring the Booking JSON.

import 'slot.dart';

class Booking {
  Booking({
    required this.id,
    required this.slot,
    required this.bookedAt,
    required this.pax,
  });

  final int      id;
  final Slot     slot;
  final DateTime bookedAt;
  final int      pax;

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'] as int,
        slot: Slot.fromJson(j['slot'] as Map<String, dynamic>),
        bookedAt: DateTime.parse(j['booked_at'] as String),
        pax: j['pax'] as int? ?? 1,
      );
}