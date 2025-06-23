// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/to/pubspec-plugin-platforms.

import 'flutter_pdf_kit_plugin_platform_interface.dart';

class FlutterPdfKitPlugin {
  /// Gets the platform version.
  ///
  /// Returns the platform version as a string, or null if unavailable.
  Future<String?> getPlatformVersion() {
    return FlutterPdfKitPluginPlatform.instance.getPlatformVersion();
  }

  /// Extracts all highlighted ranges from the given PDF file.
  ///
  /// [pdfPath] is the path to the PDF file.
  /// [allowAddingHighlights] shows PDF Viewer to add highlights
  ///
  /// Returns a list of maps, where each map contains:
  /// - "text": The highlighted string as a [String].
  /// - "color": The highlight color as a hex string (or #000000 if color is not available).
  /// - "rect": A map with keys "left", "top", "right", "bottom" representing PDF coordinates.
  Future<List<Map<String, dynamic>>?> extractHighlightedText(
    String pdfPath,
    bool allowAddingHighlights,
  ) {
    return FlutterPdfKitPluginPlatform.instance
        .extractHighlightedText(pdfPath, allowAddingHighlights);
  }
}
