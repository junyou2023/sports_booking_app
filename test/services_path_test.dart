import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no leading slashes in service API paths', () {
    final dir = Directory('lib/services');
    final reg = RegExp(r"apiClient\.(get|post|put|patch|delete)\('/");
    for (final file in dir.listSync().whereType<File>()) {
      final content = file.readAsStringSync();
      expect(reg.hasMatch(content), isFalse,
          reason: 'Leading slash found in ${file.path}');
    }
  });
}
