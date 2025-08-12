import 'package:flutter_test/flutter_test.dart';
import 'package:sports_booking_app/services/api_client.dart';

void main() {
  group('adjustBaseUrl', () {
    const url = 'http://10.0.2.2:8000/api';
    test('keeps emulator host on Android', () {
      expect(
          adjustBaseUrl(url, webOverride: false, androidOverride: true), url);
    });
    test('replaces emulator host on non-Android', () {
      expect(adjustBaseUrl(url, webOverride: false, androidOverride: false),
          'http://127.0.0.1:8000/api');
    });
  });
}
