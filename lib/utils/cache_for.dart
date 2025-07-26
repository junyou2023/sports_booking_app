import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Helper to keep an auto-disposed provider alive for a short period.
///
/// Works with any provider ref type so slot queries don't refetch when
/// navigating back and forth between pages.
extension CacheForRef<T> on AutoDisposeRef<T> {
  void cacheFor(Duration duration) {
    final link = keepAlive();
    Future.delayed(duration, link.close);
  }
}
