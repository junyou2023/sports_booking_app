import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

void showApiError(BuildContext context, DioException e, String action) {
  final status = e.response?.statusCode;
  String message;
  final data = e.response?.data;
  if (data is Map) {
    if (data['detail'] != null) {
      message = data['detail'].toString();
    } else if (data.isNotEmpty) {
      final first = data.values.first;
      if (first is List && first.isNotEmpty) {
        message = first.first.toString();
      } else {
        message = first.toString();
      }
    } else {
      message = e.message ?? '';
    }
  } else if (data is String && data.isNotEmpty) {
    message = data;
  } else {
    message = e.message ?? '';
  }
  final prefix = action.isNotEmpty ? '$action failed' : 'Error';
  final text = status != null ? '$prefix (HTTP $status): $message' : '$prefix: $message';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

