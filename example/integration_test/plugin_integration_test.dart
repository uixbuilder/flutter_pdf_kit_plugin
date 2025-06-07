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
    final tempDir = await Directory.systemTemp.createTemp();
    final pdfFile = File('${tempDir.path}/test_highlighted.pdf');
    await pdfFile.writeAsBytes(byteData.buffer.asUint8List());

    final FlutterPdfKitPlugin plugin = FlutterPdfKitPlugin();
    final highlights = await plugin.extractHighlightedText(pdfFile.path);
    print('Highlights: $highlights');
    expect(highlights, isNotNull);
    expect(highlights, isNotEmpty);
  });
}
