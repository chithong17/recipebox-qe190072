import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot:
        (String name, List<int> bytes, [Map<String, Object?>? args]) async {
          final dir = Directory('evidence');
          await dir.create(recursive: true);
          await File('${dir.path}/$name.png').writeAsBytes(bytes);
          return true;
        },
  );
}
