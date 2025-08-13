import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

/// Build an image widget that supports both local assets and network images.
/// Network images are cached and show a placeholder while loading to prevent
/// blank spaces when the connection is slow.
Widget appImage(
  String path, {
  double? width,
  double? height,
  BoxFit? fit,
}) {
  if (path.isEmpty) {
    return const SizedBox.shrink();
  }
  if (path.startsWith('assets/')) {
    return Image.asset(path, width: width, height: height, fit: fit);
  }
  final url = resolveImageUrl(path);
  return CachedNetworkImage(
    imageUrl: url,
    width: width,
    height: height,
    fit: fit,
    placeholder: (context, _) => const Center(
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
    errorWidget: (context, _, __) => const Icon(Icons.broken_image),
  );
}
