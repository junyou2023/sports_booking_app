import 'package:dio/dio.dart';
import '../models/sport.dart';
import 'api_client.dart';

/// Thin service layer – hides raw Dio from the rest of the app.
class SportsService {
  Future<List<Sport>> fetchSports() async {
    final Response<List<dynamic>> res = await apiClient.get('/sports/');
    return res.data!.map((e) => Sport.fromJson(e)).toList();
  }
}