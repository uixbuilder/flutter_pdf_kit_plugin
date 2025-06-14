import Flutter
import UIKit

public class FlutterPdfKitPlugin: NSObject, FlutterPlugin {
  public static var controlsFactory: PDFViewControlsFactory = DefaultPDFViewControlsFactory() // Default, can be swapped

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
    case "editPdfUsingViewer":
      guard let args = call.arguments as? [String: Any],
            let pdfPath = args["filePath"] as? String,
            let highlightOptions = args["highlightOptions"] as? [[String: Any]] else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments provided", details: nil))
        return
      }
      let highlightMeta = highlightOptions.compactMap { opt -> (String, String, UIColor)? in
        guard let tag = opt["tag"] as? String,
              let name = opt["name"] as? String,
              let colorHex = opt["color"] as? String,
              let color = PDFViewController.color(from: colorHex) else { return nil }

        return PDFViewController.HighlightMeta(tag: tag, title: name, color: color)
      }
      presentPdfViewer(pdfPath: pdfPath, highlightMeta: highlightMeta, flutterResult: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func presentPdfViewer(pdfPath: String, highlightMeta: [PDFViewController.HighlightMeta], flutterResult: @escaping FlutterResult) {
    guard let vc = try? PDFViewController(
      pdfURL: URL(fileURLWithPath: pdfPath),
      highlightMeta: highlightMeta,
      controlFactory: FlutterPdfKitPlugin.controlsFactory, // <-- use the static property here
      completionHandler: { didSave in
        UIApplication.shared.delegate?.window??.rootViewController?.dismiss(animated: true)
        flutterResult(didSave)
      }
    ) else {
      flutterResult(FlutterError(code: "VIEWER_CREATION_FAILED", message: "Failed to create PDF viewer", details: nil))
      return
    }
    vc.modalPresentationStyle = .fullScreen
    UIApplication.shared.delegate?.window??.rootViewController?.present(vc, animated: true)
  }

  private func extractHighlightedTextFromPdf(pdfPath: String) -> [String] {
    PDFTextExtractor().extractHighlightedText(from: URL(fileURLWithPath: pdfPath))
  }
}
