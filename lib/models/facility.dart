class Facility {
  Facility({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.radius,
    required this.categories,
  });

  final int id;
  final String name;
  final double lat;
  final double lng;
  final double radius;
  final List<String> categories;

  factory Facility.fromJson(Map<String, dynamic> j) {
    // API may return facilities either as plain objects or as GeoJSON Features
    // where the fields live inside a `properties` map. Normalize accordingly.
    final props = j['properties'] is Map
        ? Map<String, dynamic>.from(j['properties'])
        : j;

    final geomSrc = j['geometry'] ?? props['geometry'];
    if (geomSrc == null || geomSrc['coordinates'] is! List) {
      throw ArgumentError('Invalid facility geometry');
    }
    final coords = (geomSrc['coordinates'] as List).cast<num>();

    return Facility(
      id: (j['id'] ?? props['id']) as int,
      name: (props['name'] ?? j['name']) as String,
      lat: coords[1].toDouble(),
      lng: coords[0].toDouble(),
      radius: ((props['radius'] ?? j['radius']) as num).toDouble(),
      categories: ((props['categories'] ?? j['categories']) as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
