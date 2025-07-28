class Paginated<T> {
  Paginated({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final list = (json['results'] as List?)
            ?.cast<Map<String, dynamic>>()
            .map(fromJson)
            .toList(growable: false) ??
        <T>[];
    return Paginated(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: list,
    );
  }
}
