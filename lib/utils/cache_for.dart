import 'package:flutter_riverpod/flutter_riverpod.dart';

extension CacheForRef on Ref<Object?> {
  void cacheFor(Duration duration) {
    final link = keepAlive();
    Future.delayed(duration, link.close);
  }
}
