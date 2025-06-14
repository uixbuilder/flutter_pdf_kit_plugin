import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_pdf_kit_plugin/flutter_pdf_kit_plugin.dart';
import 'package:flutter_pdf_kit_plugin/flutter_pdf_kit_plugin_platform_interface.dart';
import 'package:flutter_pdf_kit_plugin/flutter_pdf_kit_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter_pdf_kit_plugin/highlight_option.dart';

class MockFlutterPdfKitPluginPlatform
    with MockPlatformInterfaceMixin
    implements FlutterPdfKitPluginPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<List<String>?> extractHighlightedText(String pdfPath) {
    throw UnimplementedError(
      'extractHighlightedText() has not been implemented.',
    );
  }

  @override
  Future<bool> highlightTextInPdf(String pdfPath, String textToHighlight) {
    throw UnimplementedError(
      'highlightTextInPdf() has not been implemented.',
    );
  }

  @override
  Future<bool> editPdfUsingViewer(
      String filePath, List<HighlightOption> highlightOptions) {
    throw UnimplementedError('editPdfUsingViewer() has not been implemented.');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final FlutterPdfKitPluginPlatform initialPlatform =
      FlutterPdfKitPluginPlatform.instance;

  test('$MethodChannelFlutterPdfKitPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterPdfKitPlugin>());
  });

  test('getPlatformVersion', () async {
    FlutterPdfKitPlugin flutterPdfKitPlugin = FlutterPdfKitPlugin();
    MockFlutterPdfKitPluginPlatform fakePlatform =
        MockFlutterPdfKitPluginPlatform();
    FlutterPdfKitPluginPlatform.instance = fakePlatform;

    expect(await flutterPdfKitPlugin.getPlatformVersion(), '42');
  });
}
