class Variant {
  Variant({required this.id, required this.discipline, required this.name});

  final int id;
  final int discipline;
  final String name;

  factory Variant.fromJson(Map<String, dynamic> j) => Variant(
        id: j['id'] as int,
        discipline: j['discipline'] as int,
        name: j['name'] as String,
      );
}
