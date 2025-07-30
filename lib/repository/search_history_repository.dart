import 'package:shared_preferences/shared_preferences.dart';

/// Maintains a simple local search history list of up to 10 unique terms.
class SearchHistoryRepository {
  static const _key = 'search_history';

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? <String>[];
  }

  Future<void> add(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_key) ?? <String>[];
    history.remove(query);
    history.insert(0, query);
    if (history.length > 10) {
      history.removeRange(10, history.length);
    }
    await prefs.setStringList(_key, history);
  }
}

final searchHistoryRepository = SearchHistoryRepository();
