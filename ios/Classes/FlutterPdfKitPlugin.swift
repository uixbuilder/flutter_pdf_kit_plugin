import Flutter
import UIKit
import PDFKit

public class FlutterPdfKitPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_pdf_kit_plugin", binaryMessenger: registrar.messenger())
    let instance = FlutterPdfKitPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
      case "extractHighlightedText":
      guard let args = call.arguments as? [String: Any],
            let pdfPath = args["filePath"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments provided", details: nil))
        return
      }

      var highlightedTexts = extractHighlightedTextFromPdf(pdfPath: pdfPath)
      result(highlightedTexts)
    case "highlightTextInPdf":
      guard let args = call.arguments as? [String: Any],
            let pdfPath = args["filePath"] as? String,
            let textToHighlight = args["textToHighlight"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments provided", details: nil))
        return
      }

      let success = highlightTextInPdf(pdfPath: pdfPath, textToHighlight: textToHighlight)
      result(success)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func extractHighlightedTextFromPdf(pdfPath: String) -> [String] {
    PDFTextExtractor().extractHighlightedText(from: URL(fileURLWithPath: pdfPath))
  }

  private func highlightTextInPdf(pdfPath: String, textToHighlight: String) -> Bool {
    PDFTextHighlighter().highlightTextInPdf(pdfURL: URL(fileURLWithPath: pdfPath), textToHighlight: textToHighlight)
  }
}
