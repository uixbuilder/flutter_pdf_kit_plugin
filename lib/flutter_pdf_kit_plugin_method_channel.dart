import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_pdf_kit_plugin_platform_interface.dart';

/// An implementation of [FlutterPdfKitPluginPlatform] that uses method channels.
class MethodChannelFlutterPdfKitPlugin extends FlutterPdfKitPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_pdf_kit_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<List<String>?> extractHighlightedText(String pdfPath) async {
    final highlights = await methodChannel.invokeMethod<List<dynamic>>(
      'extractHighlightedText',
      <String, dynamic>{'filePath': pdfPath},
    );
    return highlights?.cast<String>();
  }

  @override
  Future<bool> highlightTextInPdf(
      String pdfPath, String textToHighlight) async {
    final result = await methodChannel.invokeMethod<bool>(
      'highlightTextInPdf',
      <String, dynamic>{
        'filePath': pdfPath,
        'textToHighlight': textToHighlight,
      },
    );
    return result ?? false;
  }
}
