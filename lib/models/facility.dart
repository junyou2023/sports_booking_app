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
    final geom = j['geometry']['coordinates'] as List;
    return Facility(
      id: j['id'] as int,
      name: j['name'] as String,
      lat: geom[1] as double,
      lng: geom[0] as double,
      radius: (j['radius'] as num).toDouble(),
      categories: (j['categories'] as List).cast<int>().map((e) => e.toString()).toList(),
    );
  }
}
