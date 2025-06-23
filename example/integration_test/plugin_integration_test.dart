// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_pdf_kit_plugin/flutter_pdf_kit_plugin.dart';
import 'dart:io';
import 'package:flutter/services.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getPlatformVersion test', (WidgetTester tester) async {
    final FlutterPdfKitPlugin plugin = FlutterPdfKitPlugin();
    final String? version = await plugin.getPlatformVersion();
    // The version string depends on the host platform running the test, so
    // just assert that some non-empty string is returned.
    expect(version?.isNotEmpty, true);
  });

  testWidgets('extracts highlighted text from PDF', (
    WidgetTester tester,
  ) async {
    // Load the PDF asset from pubspec.yaml (make sure it's listed under flutter: assets:)
    final byteData = await rootBundle.load(
      'integration_test/assets/test_highlighted.pdf',
    );

    // Write PDF data to a temporary file so the plugin can work with a file path.
    final tempDir = await Directory.systemTemp.createTemp();
    final pdfFile = File('${tempDir.path}/test_highlighted.pdf');
    await pdfFile.writeAsBytes(byteData.buffer.asUint8List());

    // Create an instance of the plugin to call the method.
    final FlutterPdfKitPlugin plugin = FlutterPdfKitPlugin();
    final highlights = await plugin.extractHighlightedText(pdfFile.path, false);

    // Clean up the temporary file
    await pdfFile.delete();
    await tempDir.delete();

    // Verify that the highlights were extracted correctly as a list of maps.
    expect(highlights, isNotNull);
    expect(highlights!.length, 1);

    final first = highlights[0];
    expect(first, isA<Map<String, dynamic>>());
    expect(first['text'], 'reasons: for fresh air');
    expect(first['color'], '#FFFF00');
    expect(first['rect'], isA<Map>());
    expect(first['rect']['left'], isA<num>());
    expect(first['rect']['top'], isA<num>());
    expect(first['rect']['right'], isA<num>());
    expect(first['rect']['bottom'], isA<num>());
    expect(first['rect']['left'], closeTo(164.042, 0.01));
    expect(first['rect']['top'], closeTo(554.364, 0.01));
    expect(first['rect']['right'], closeTo(318.121, 0.01));
    expect(first['rect']['bottom'], closeTo(567.924, 0.01));
  });
}
