import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Singleton Dio client configured with base URL and JSON defaults.
final Dio apiClient = Dio(
  BaseOptions(
    baseUrl: dotenv.env['API_BASE_URL']!,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
    responseType: ResponseType.json,
  ),
);