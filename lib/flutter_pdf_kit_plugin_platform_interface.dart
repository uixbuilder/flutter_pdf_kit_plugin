import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'flutter_pdf_kit_plugin_method_channel.dart';

abstract class FlutterPdfKitPluginPlatform extends PlatformInterface {
  /// Constructs a FlutterPdfKitPluginPlatform.
  FlutterPdfKitPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterPdfKitPluginPlatform _instance =
      MethodChannelFlutterPdfKitPlugin();

  /// The default instance of [FlutterPdfKitPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterPdfKitPlugin].
  static FlutterPdfKitPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterPdfKitPluginPlatform] when
  /// they register themselves.
  static set instance(FlutterPdfKitPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Extracts all highlighted ranges from the given PDF.
  /// Returns a list of maps, each containing:
  ///  - "text": the highlighted string
  ///  - "color": highlight color as hex string (or #000000 if color is not available)
  ///  - "rect": a map {"left", "top", "right", "bottom"} (PDF coordinates)
  Future<List<Map<String, dynamic>>?> extractHighlightedText(
    String pdfPath,
    bool allowAddingHighlights,
  ) {
    throw UnimplementedError(
      'extractHighlightedText() has not been implemented.',
    );
  }
}
