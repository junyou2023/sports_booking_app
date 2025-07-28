import 'activity.dart';

class ActivityPage {
  ActivityPage({required this.results, required this.count});

  final List<Activity> results;
  final int count;

  factory ActivityPage.fromJson(Map<String, dynamic> j) => ActivityPage(
        results: (j['results'] as List)
            .cast<Map<String, dynamic>>()
            .map(Activity.fromJson)
            .toList(growable: false),
        count: j['count'] as int? ?? 0,
      );
}
