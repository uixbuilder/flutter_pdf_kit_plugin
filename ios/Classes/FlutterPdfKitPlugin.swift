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
      else {
        presentPdfViewer(pdfPath: pdfPath, flutterResult: result)
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

  private func presentPdfViewer(pdfPath: String, flutterResult: @escaping FlutterResult) {
    guard let topViewController = topViewController() else {
      flutterResult(FlutterError(code: "NO_TOP_CONTROLLER", message: "No top view controller found", details: nil))
      return
    }

    guard let vc = try? PDFViewController(
      pdfURL: URL(fileURLWithPath: pdfPath),
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
      let button = UIButton(primaryAction: UIAction(image: UIImage(named: "back-button"), handler: { _ in
          topViewController.dismiss(animated: true)
          flutterResult(nil)
      }))
      button.tintColor = .white
      let backItem = UIBarButtonItem(customView: button)
      vc.navigationItem.leftBarButtonItem = backItem
      
      if let navigationController = topViewController as? UINavigationController {
          navigationController.pushViewController(vc, animated: false)
      }
      else {
          let navigationController = UINavigationController(rootViewController: vc)
          navigationController.hidesBarsOnSwipe = false
          let appearance = UINavigationBarAppearance()
          appearance.configureWithOpaqueBackground()
          appearance.backgroundColor = .black
          appearance.titleTextAttributes = [.foregroundColor: UIColor.white,
                                            .font: UIFont(name: "SheillaMonicaRegular", size: 24) ??
                                            UIFont.systemFont(ofSize: 24, weight: .regular)]
          navigationController.navigationBar.standardAppearance = appearance
          navigationController.navigationBar.scrollEdgeAppearance = appearance
          navigationController.navigationBar.compactAppearance = appearance
          navigationController.navigationBar.isTranslucent = false
          navigationController.modalPresentationStyle = .fullScreen
          topViewController.present(navigationController, animated: true)
      }
  }

    private func extractHighlightedTextFromPdf(document: PDFDocument) -> [[String: Any]] {
    PDFTextExtractor().extractHighlightedText(from: document)
  }
}
