import 'package:flutter_test/flutter_test.dart';

class RefreshQueue {
  Future<void>? _refreshing;
  int refreshCalls = 0;

  Future<T> handle401<T>(Future<T> Function() retry) async {
    _refreshing ??=
        Future(() async { refreshCalls++; await Future.delayed(const Duration(milliseconds: 10)); })
            .whenComplete(() => _refreshing = null);
    await _refreshing;
    return retry();
  }
}

void main() {
  test('queues 401s and refreshes only once', () async {
    final q = RefreshQueue();
    var completed = 0;
    Future<void> req() async {
      await q.handle401(() async { completed++; });
    }
    await Future.wait([req(), req(), req()]);
    expect(q.refreshCalls, 1);
    expect(completed, 3);
  });
}
