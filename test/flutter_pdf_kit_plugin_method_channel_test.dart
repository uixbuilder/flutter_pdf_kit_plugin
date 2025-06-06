import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_pdf_kit_plugin/flutter_pdf_kit_plugin_method_channel.dart';

void main() {
  MethodChannelFlutterPdfKitPlugin platform = MethodChannelFlutterPdfKitPlugin();
  const MethodChannel channel = MethodChannel('flutter_pdf_kit_plugin');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
