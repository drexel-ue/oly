import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> imageBytes, [Map<String, dynamic>? args]) async {
      final Directory dir = Directory('screenshots');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final File file = File('screenshots/$name.png');
      await file.writeAsBytes(imageBytes);
      // ignore: avoid_print
      print(
        '📸 Captured screenshot: screenshots/$name.png (${imageBytes.length} bytes)',
      );
      return true;
    },
  );
}
