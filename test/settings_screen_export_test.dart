import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'lib/screens/settings_screen.dart contains Export Data option',
    () async {
      final file = File('lib/screens/settings_screen.dart');
      final content = await file.readAsString();
      expect(content.contains('Export Data (CSV)'), isTrue);
    },
  );
}
