class Facility {
  Facility({
    required this.id,
    required this.name,
    required this.radius,
    required this.categories,
    this.address = '',
    this.lat,
    this.lng,
  });

  final int id;
  final String name;
  final double radius;
  final List<String> categories;
  final String address;
  final double? lat;
  final double? lng;

  bool get hasLocation => lat != null && lng != null;

  factory Facility.fromJson(Map<String, dynamic> j) {
    double? lat;
    double? lng;
    final geom = j['geometry'];
    if (geom is Map && geom['coordinates'] is List) {
      final coords = geom['coordinates'] as List;
      if (coords.length >= 2) {
        lat = (coords[1] as num).toDouble();
        lng = (coords[0] as num).toDouble();
      }
    } else {
      if (j['lat'] != null && j['lng'] != null) {
        lat = (j['lat'] as num).toDouble();
        lng = (j['lng'] as num).toDouble();
      }
    }
    return Facility(
      id: j['id'] as int,
      name: j['name'] as String,
      address: j['address'] as String? ?? '',
      lat: lat,
      lng: lng,
      radius: (j['radius'] as num).toDouble(),
      categories:
          (j['categories'] as List).cast<int>().map((e) => e.toString()).toList(),
    );
  }
}
