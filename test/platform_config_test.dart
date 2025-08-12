import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AndroidManifest has INTERNET permission', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest.contains('android.permission.INTERNET'), isTrue);
  });

  test('Info.plist allows HTTP loads in development', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist.contains('NSAppTransportSecurity'), isTrue);
    expect(plist.contains('NSAllowsArbitraryLoads'), isTrue);
  });
}
