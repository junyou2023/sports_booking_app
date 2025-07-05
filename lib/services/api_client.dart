/// Global Dio instance configured with base-url and sane defaults.
/// All services import this instead of creating their own client.

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final Dio apiClient = Dio(
  BaseOptions(
    baseUrl: dotenv.env['API_BASE_URL']!, // e.g. http://10.0.2.2:8000/api
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
    responseType: ResponseType.json,
  ),
);
