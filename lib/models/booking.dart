// lib/models/booking.dart
//
// Local model mirroring the Booking JSON.

import 'slot.dart';

class Booking {
  Booking({
    required this.id,
    required this.slot,
    required this.created,
    required this.status,
  });

  final int        id;
  final Slot       slot;
  final DateTime   created;
  final String     status;   // P / C / X

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
    id:      j['id']     as int,
    slot:    Slot.fromJson(j['slot'] as Map<String, dynamic>),
    created: DateTime.parse(j['created'] as String),
    status:  j['status'] as String,
  );
}