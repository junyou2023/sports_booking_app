// lib/services/sports_service.dart
//
// All networking logic related to “sports” AND “slots” lives here.
// The class is intentionally kept *very* small: pure functions that
// perform REST calls and return parsed model objects.  Nothing else.

import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/sport.dart';
import '../models/slot.dart';
import '../models/category.dart';
import '../models/variant.dart';
import 'api_client.dart';

class SportsService {
  /// GET /api/sports/
  Future<List<Sport>> fetchSports() async {
    final res = await apiClient.get('/sports/');
    final list = (res.data as List)
        .cast<Map<String, dynamic>>()
        .map(Sport.fromJson)
        .toList(growable: false);
    return list;
  }

  /// GET /api/slots/
  ///
  /// The backend returns ALL upcoming slots (future dates only).
  /// You can add query-string filters on the API later as needed.
  Future<List<Slot>> fetchSlots() async {
    final res = await apiClient.get('/slots/');
    final list = (res.data as List)
        .cast<Map<String, dynamic>>()
        .map(Slot.fromJson)
        .toList(growable: false);
    return list;
  }

  Future<List<Category>> fetchCategories() async {
    final res = await apiClient.get('/categories/');
    return (res.data as List)
        .cast<Map<String, dynamic>>()
        .map(Category.fromJson)
        .toList(growable: false);
  }

  Future<List<Variant>> fetchVariants() async {
    final res = await apiClient.get('/variants/');
    return (res.data as List)
        .cast<Map<String, dynamic>>()
        .map(Variant.fromJson)
        .toList(growable: false);
  }
}

final sportsService = SportsService();
