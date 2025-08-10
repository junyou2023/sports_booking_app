class Organization {
  final int id;
  final String name;
  final String slug;
  final String role;

  Organization({
    required this.id,
    required this.name,
    required this.slug,
    required this.role,
  });

  factory Organization.fromJson(Map<String, dynamic> j) => Organization(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
        role: j['role'] as String? ?? '',
      );
}
