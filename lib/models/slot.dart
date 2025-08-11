// lib/models/slot.dart
import 'sport.dart';

class Slot {
  Slot({
    required this.id,
    required this.sport,
    required this.activityId,
    this.facilityId,
    required this.title,
    required this.location,
    required this.beginsAt,
    required this.endsAt,
    required this.capacity,
    required this.price,
    required this.rating,
    required this.seatsLeft,
  });

  final int      id;
  final Sport    sport;
  final int      activityId;
  final int?     facilityId;
  final String   title;
  final String   location;
  final DateTime beginsAt;
  final DateTime endsAt;
  final int      capacity;
  final double   price;
  final double   rating;
  final int      seatsLeft;

  /// Allows backend to return either sport=ID or sport=Map
  factory Slot.fromJson(Map<String, dynamic> j) {
    final dynamic sportRaw = j['sport'];

    /// Parse Sport
    late final Sport sport;
    if (sportRaw is Map<String, dynamic>) {
      sport = Sport.fromJson(sportRaw);
    } else if (sportRaw is int) {
      // If only an ID is provided create placeholder Sport and lazy load details
      sport = Sport(id: sportRaw, name: '', banner: '', description: '');
    } else {
      throw const FormatException('Unsupported sport payload');
    }

    return Slot(
      id:         j['id']               as int,
      sport:      sport,
      activityId: j['activity']         as int,
      facilityId: j['facility']         as int?,
      title:      j['title']            as String,
      location:   j['location']         as String,
      beginsAt:   DateTime.parse(j['begins_at'] as String),
      endsAt:     DateTime.parse(j['ends_at']   as String),
      capacity:   j['capacity']         as int,
      price:      double.parse(j['price'].toString()),
      rating:     double.parse(j['rating'].toString()),
      seatsLeft:  j['seats_left']       as int? ?? j['capacity'] as int,
    );
  }

  /// Convenience for potential future write operations
  Map<String, dynamic> toJson() => {
    'id'        : id,
    'sport'     : sport.id,
    'activity'  : activityId,
    if (facilityId != null) 'facility': facilityId,
    'title'     : title,
    'location'  : location,
    'begins_at' : beginsAt.toIso8601String(),
    'ends_at'   : endsAt.toIso8601String(),
    'capacity'  : capacity,
    'price'     : price,
    'rating'    : rating,
    'seats_left': seatsLeft,
  };
}
