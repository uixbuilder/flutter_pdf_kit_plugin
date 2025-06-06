import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_pdf_kit_plugin/flutter_pdf_kit_plugin.dart';
import 'package:flutter_pdf_kit_plugin/flutter_pdf_kit_plugin_platform_interface.dart';
import 'package:flutter_pdf_kit_plugin/flutter_pdf_kit_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterPdfKitPluginPlatform
    with MockPlatformInterfaceMixin
    implements FlutterPdfKitPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterPdfKitPluginPlatform initialPlatform = FlutterPdfKitPluginPlatform.instance;

  test('$MethodChannelFlutterPdfKitPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterPdfKitPlugin>());
  });

  test('getPlatformVersion', () async {
    FlutterPdfKitPlugin flutterPdfKitPlugin = FlutterPdfKitPlugin();
    MockFlutterPdfKitPluginPlatform fakePlatform = MockFlutterPdfKitPluginPlatform();
    FlutterPdfKitPluginPlatform.instance = fakePlatform;

    expect(await flutterPdfKitPlugin.getPlatformVersion(), '42');
  });
}
