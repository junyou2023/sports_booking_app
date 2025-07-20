import '../models/sport_category.dart';
import 'api_client.dart';

class SportCategoryService {
  Future<List<SportCategory>> fetchCategories() async {
    final res = await apiClient.get('/sport-categories/');
    final list = (res.data as List)
        .cast<Map<String, dynamic>>()
        .map(SportCategory.fromJson)
        .toList(growable: false);
    return list;
  }

  Future<void> createCategory(String name, int? parent) async {
    await apiClient.post('/sport-categories/', data: {
      'name': name,
      'parent': parent,
    });
  }

  Future<void> updateCategory(int id, String name, int? parent) async {
    await apiClient.patch('/sport-categories/' + id.toString() + '/', data: {
      'name': name,
      'parent': parent,
    });
  }

  Future<void> deleteCategory(int id) async {
    await apiClient.delete('/sport-categories/' + id.toString() + '/');
  }
}

final sportCategoryService = SportCategoryService();
