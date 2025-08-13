import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Resolve relative media paths returned by the backend into absolute URLs.
/// If the [path] is already an absolute http(s) URL or an asset reference,
/// it is returned unchanged.
String resolveImageUrl(String path) {
  if (path.isEmpty || path.startsWith('http') || path.startsWith('assets/')) {
    return path;
  }
  final base = dotenv.env['API_BASE_URL'] ?? '';
  // Remove trailing "/api" segment to get the server origin for media files.
  final origin = base.replaceFirst(RegExp(r'/api/?$'), '');
  if (!path.startsWith('/')) {
    path = '/$path';
  }
  return '$origin$path';
}
