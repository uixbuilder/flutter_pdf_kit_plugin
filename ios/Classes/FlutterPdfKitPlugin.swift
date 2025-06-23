import Flutter
import UIKit
import PDFKit

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
      // Expects arguments: ["filePath": String, "allowAddingHighlights": String]
      // Returns: [[String: Any]]
      // Each dictionary contains:
      //   - "text": The highlighted string (String)
      //   - "color": The highlight color as a hex string (String?) or nil
      //   - "rect": The bounding rectangle in PDF coordinates (["left", "top", "right", "bottom"])
      //   - "pageIndex": The page index where the highlight is found (Int)
      guard let args = call.arguments as? [String: Any],
            let pdfPath = args["filePath"] as? String,
            let allowAddingHighlights = args["allowAddingHighlights"] as? Bool else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments provided", details: nil))
        return
      }

      if allowAddingHighlights == false {
          guard let pdfDocument = PDFDocument(url: URL(filePath: pdfPath)) else {
              result(FlutterError(code: "FILE_READING_FAILED", message: "Failed to read PDF file", details: nil))
              return
          }
          
          let highlightedTexts = extractHighlightedTextFromPdf(document: pdfDocument)
          result(highlightedTexts)
      }
      else if let lineColor = PDFViewController.color(from: "#FFFF00"),
              let nameColor = PDFViewController.color(from: "#00FF00")
      {
        let highlightMeta = [
          PDFViewController.HighlightMeta(tag: "character_line", title: "Character's lines", color: lineColor),
          PDFViewController.HighlightMeta(tag: "character_name", title: "Character's name", color: nameColor)
        ]
        
        presentPdfViewer(pdfPath: pdfPath, highlightMeta: highlightMeta, flutterResult: result)
      }
      else {
        result(FlutterError(code: "COLOR_CREATION_FAILED", message: "Failed to create highlight colors", details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func topViewController(base: UIViewController? = UIApplication.shared.connectedScenes
    .compactMap { ($0 as? UIWindowScene)?.keyWindow }
    .first?.rootViewController) -> UIViewController? {
  if let nav = base as? UINavigationController {
    return topViewController(base: nav.visibleViewController)
  }
  if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
    return topViewController(base: selected)
  }
  if let presented = base?.presentedViewController {
    return topViewController(base: presented)
  }
  return base
}

  private func presentPdfViewer(pdfPath: String, highlightMeta: [PDFViewController.HighlightMeta], flutterResult: @escaping FlutterResult) {
    guard let topViewController = topViewController() else {
      flutterResult(FlutterError(code: "NO_TOP_CONTROLLER", message: "No top view controller found", details: nil))
      return
    }

    guard let vc = try? PDFViewController(
      pdfURL: URL(fileURLWithPath: pdfPath),
      highlightMeta: highlightMeta,
      controlFactory: FlutterPdfKitPlugin.controlsFactory, // <-- use the static property here
      completionHandler: { [weak self] document in
        topViewController.dismiss(animated: true)
          guard let self, let document else {
              flutterResult(nil)
              return
          }
          
          flutterResult(self.extractHighlightedTextFromPdf(document: document))
      }
    ) else {
      flutterResult(FlutterError(code: "VIEWER_CREATION_FAILED", message: "Failed to create PDF viewer", details: nil))
      return
    }
    vc.modalPresentationStyle = .fullScreen
    topViewController.present(vc, animated: true)
  }

    private func extractHighlightedTextFromPdf(document: PDFDocument) -> [[String: Any]] {
    PDFTextExtractor().extractHighlightedText(from: document)
  }
}
