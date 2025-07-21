import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/sports_service.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return sportsService.fetchCategories();
});
