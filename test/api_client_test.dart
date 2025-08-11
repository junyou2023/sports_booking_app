import 'package:flutter_test/flutter_test.dart';
import 'package:sports_booking_app/services/api_client.dart';

void main() {
  test('replace 10.0.2.2 on web/desktop', () {
    final url = adjustBaseUrl('http://10.0.2.2:8000/api', webOverride: true);
    expect(url, 'http://127.0.0.1:8000/api');
  });

  test('keep 10.0.2.2 on android', () {
    final url = adjustBaseUrl('http://10.0.2.2:8000/api',
        webOverride: false, desktopOverride: false);
    expect(url, 'http://10.0.2.2:8000/api');
  });
}
