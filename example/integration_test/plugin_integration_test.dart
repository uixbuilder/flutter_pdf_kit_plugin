// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'dart:math';

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
    expect(highlights, isNotNull);
    expect(highlights!.length, 1);
    expect(highlights[0], 'reasons: for fresh air');
  });

  testWidgets('highlight text in PDF', (WidgetTester tester) async {
    // 1. Load the PDF asset. Make sure 'clear_sample.pdf' is listed under flutter: assets: in pubspec.yaml.
    final byteData = await rootBundle.load(
      'integration_test/assets/clear_sample.pdf',
    );

    // 2. Write PDF data to a temporary file so the plugin can work with a file path.
    final tempDir = await Directory.systemTemp.createTemp();
    final pdfFile = File('${tempDir.path}/test.pdf');
    await pdfFile.writeAsBytes(byteData.buffer.asUint8List());

    final FlutterPdfKitPlugin plugin = FlutterPdfKitPlugin();

    // 3. Attempt to highlight a known phrase in the PDF.
    final textToHighlight = 'reasons: for fresh air';
    final result =
        await plugin.highlightTextInPdf(pdfFile.path, textToHighlight);

    // 4. Check that the plugin reported a successful highlight operation.
    expect(result, isTrue,
        reason: 'Highlight should be successfully added to the PDF');

    // 5. Extract highlighted texts and verify the content matches.
    final highlights = await plugin.extractHighlightedText(pdfFile.path);

    expect(highlights, isNotNull,
        reason: 'Extracted highlights should not be null');
    expect(highlights!.length, 1,
        reason: 'Exactly one highlight should be present');
    expect(
      highlights[0],
      textToHighlight,
      reason: 'The highlighted text should exactly match the expected phrase',
    );

    // Optional: clean up
    await pdfFile.delete();
    await tempDir.delete();
  });
}
