import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sport_category.dart';
import '../services/sport_category_service.dart';

final sportCategoriesProvider = FutureProvider<List<SportCategory>>((ref) async {
  return sportCategoryService.fetchCategories();
});
