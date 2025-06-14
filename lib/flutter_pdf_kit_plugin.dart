// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/to/pubspec-plugin-platforms.

import 'flutter_pdf_kit_plugin_platform_interface.dart';
import 'highlight_option.dart';

class FlutterPdfKitPlugin {
  Future<String?> getPlatformVersion() {
    return FlutterPdfKitPluginPlatform.instance.getPlatformVersion();
  }

  Future<List<String>?> extractHighlightedText(String pdfPath) {
    return FlutterPdfKitPluginPlatform.instance.extractHighlightedText(pdfPath);
  }

  /// Opens a native PDF viewer for editing, with customizable highlighting options.
  ///
  /// [filePath] is the path to the PDF file.
  /// [highlightOptions] is a list of [HighlightOption] objects specifying highlight tags, names, and colors.
  Future<bool> editPdfUsingViewer(
    String filePath,
    List<HighlightOption> highlightOptions,
  ) {
    return FlutterPdfKitPluginPlatform.instance
        .editPdfUsingViewer(filePath, highlightOptions);
  }
}
