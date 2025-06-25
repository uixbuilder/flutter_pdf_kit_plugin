import Foundation
import PDFKit
import UIKit

/// A view controller that provides interactive PDF viewing and annotation capabilities.
///
/// `PDFViewController` enables users to view, highlight, and remove highlights from PDF documents.
/// The controller relies on a control factory for all UI buttons, and exposes completion handlers
/// for save and close events.
public class PDFViewController: UIViewController, PDFViewDelegate {
    /// A handler called on completion of save/close events.
    public typealias CompletionHandler = (_ highlightedPDF: PDFDocument?) -> Void
    enum HighlightType: Equatable, Hashable {
        case character
        case dialogue
        
        func color() -> UIColor {
            switch self {
            case .character:
                return PDFViewController.color(from: "#FF9E00")!
            case .dialogue:
                return PDFViewController.color(from: "#F1C680")!
            }
        }
    }

    enum EditingMode: Equatable, Hashable {
        case highlight(HighlightType)
        case eraser
        
        static var highlightAny: Self {
            .highlight(.character)
        }
    }
    
    private var longPressStartPage: PDFPage?
    private var longPressStartLocation: CGPoint?
    private var previewAnnotationsMap: [String: PDFAnnotation] = [:]
    
    private let pdfView = PDFView()
    private let document: PDFDocument
    private var highlightModeButton: UIButton?
    private var eraserModeButton: UIButton?
    private var extractActionButton: UIButton?
    
    private var editingMode: EditingMode? {
        didSet {
            eraserModeButton?.isSelected = editingMode == .eraser
            highlightModeButton?.isSelected = editingMode != .eraser
        }
    }
    
    private var selectedHighlight: PDFAnnotation?
    
    /// Initializes a PDFViewController with the given PDF and annotation options.
    ///
    /// - Parameters:
    ///   - pdfURL: The URL of the PDF document to display.
    ///   - highlightMeta: The metadata describing available highlight actions (tag, title, color).
    ///   - controlFactory: An instance conforming to `PDFViewControlsFactory` for creating UI controls.
    ///   - completionHandler: A closure called when the user saves or closes the viewer.
    /// - Throws: An error if the PDF document cannot be loaded from the given URL.
    public init(
        pdfURL: URL,
        completionHandler: @escaping CompletionHandler
    ) throws {
        if let document = PDFDocument(url: pdfURL) {
            self.document = document
            super.init(nibName: nil, bundle: nil)
            
            self.extractActionButton = UIButton(configuration: .plain(), primaryAction: UIAction { [weak self] _ in
                completionHandler(self?.document)
            })
            
            self.title = pdfURL.lastPathComponent.replacingOccurrences(of: ".\(pdfURL.pathExtension)", with: "")
        }
        else {
            throw NSError(domain: CocoaError.errorDomain, code: CocoaError.fileReadCorruptFile.rawValue)
        }
    }
    
    /// Initializes a new instance from a decoder.
    /// - Parameter coder: The decoder to initialize from.
    /// - Note: This initializer is not implemented and will cause a runtime error if called.
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    fileprivate func makeToolButton(_ imageName: String, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(configuration: .plain(), primaryAction: UIAction { _ in action() })
        button.configuration?.image = UIImage(named: imageName) ?? (imageName == "eraser" ? UIImage(systemName: "eraser.line.dashed") : UIImage(systemName: "highlighter"))
        button.configuration?.contentInsets = .init(top: 24, leading: 18, bottom: 24, trailing: 18)
        button.configurationUpdateHandler = { button in
            var config = button.configuration
            config?.background.cornerRadius = 0
            config?.background.backgroundColor = (button.isSelected || button.isHighlighted) ? Self.color(from: "#C19C60") : .black.withAlphaComponent(0.5)
            button.configuration = config
        }
        button.tintColor = .white
        button.layer.cornerRadius = 12
        button.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        button.clipsToBounds = true
        
        return button
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        attachPDFView()
        attachEditModeButtons()
        attachExtractButton()
        setupObserving()
    }
    
    private func presentLineTypeSelectionSheet(completion: @escaping (HighlightType) -> Void) {
        let alertController = HighlighterTypeSheetController { [weak self] action in
            if action != .close {
                completion(action == .character ? .character : .dialogue)
            }
            
            self?.dismiss(animated: true)
        }
        
        self.present(alertController, animated: true)
    }
    
    // MARK: - UI construction Methods
    
    private func attachEditModeButtons() {
        let eraserButton = makeToolButton("eraser") { [weak self] in self?.editingMode = .eraser}
        let highlightButton = makeToolButton("highlighter") { [weak self] in
            self?.presentLineTypeSelectionSheet() { highlightType in
                self?.editingMode = .highlight(highlightType)
            }
        }
        
        eraserModeButton = eraserButton
        highlightModeButton = highlightButton
        
        let stackView = UIStackView(arrangedSubviews: [highlightButton, eraserButton])
        stackView.spacing = 20
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            view.centerYAnchor.constraint(equalTo: stackView.centerYAnchor),
        ])
    }
    
    private func attachExtractButton() {
        guard let extractActionButton else { return }
        
        extractActionButton.configurationUpdateHandler = { [weak self] button in
            guard var config = button.configuration else { return }
            
            config.background.backgroundColor = Self.color(from: "#C19C60")
            config.baseForegroundColor = .white
            config.cornerStyle = .capsule
            if let count = self?.pdfView.currentPage?.annotations.count {
                config.attributedTitle = AttributedString(
                    "Extract (\(count)) Lines",
                    attributes: AttributeContainer([.font: UIFont.monospacedSystemFont(ofSize: 18, weight: .bold)])
                )
                button.isEnabled = true
            } else {
                config.attributedTitle = AttributedString(
                    "Extract Lines",
                    attributes: AttributeContainer([.font: UIFont.monospacedSystemFont(ofSize: 18, weight: .bold)])
                )
                button.isEnabled = false
            }
            config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            button.configuration = config
        }
        
        extractActionButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(extractActionButton)
        
        NSLayoutConstraint.activate([
            extractActionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            extractActionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            extractActionButton.widthAnchor.constraint(equalToConstant: 305),
            extractActionButton.heightAnchor.constraint(equalToConstant: 51)
        ])

    }
    
    private func attachPDFView() {
        pdfView.document = document
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pdfView)
        NSLayoutConstraint.activate([
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        pdfView.autoScales = true
        pdfView.delegate = self
    }
    
    // MARK: - Actions handling Methods
    
    private func setupObserving() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(selectionChanged),
            name: Notification.Name.PDFViewSelectionChanged,
            object: pdfView
        )
        
        pdfView.documentView?.interactions.compactMap { $0 as? UIEditMenuInteraction }
            .forEach { pdfView.documentView?.removeInteraction($0) }
        pdfView.documentView?.gestureRecognizers?.compactMap { $0 as? UILongPressGestureRecognizer }.forEach {
            $0.isEnabled = false
        }
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleUserDidTap))
        tapRecognizer.delegate = self
        view.addGestureRecognizer(tapRecognizer)
        
        let longPressRecongizer = UILongPressGestureRecognizer(target: self, action: #selector(handleUserDidLongPress))
        longPressRecongizer.delegate = self
        longPressRecongizer.minimumPressDuration = 0.2
        view.addGestureRecognizer(longPressRecongizer)
    }
    
    @objc
    private func handleUserDidLongPress(recognizer: UILongPressGestureRecognizer) {
        let location = recognizer.location(in: pdfView)
        guard let page = pdfView.page(for: location, nearest: true),
              case let .highlight(highlightType) = editingMode
        else { return }
        
        let pdfLocation = pdfView.convert(location, to: page)
        
        switch recognizer.state {
        case .began:
            // Save the start position and page
            longPressStartPage = page
            longPressStartLocation = pdfLocation
        case .changed:
            guard let startPage = longPressStartPage,
                  let startLocation = longPressStartLocation,
                  startPage == page else { return }
            
            if let selection = page.selection(from: startLocation, to: pdfLocation) {
                // 0. Copy the previewAnnotationsMap
                var oldAnnotations = previewAnnotationsMap
                
                // 1. Iterate through selectionsByLine()
                for line in selection.selectionsByLine() {
                    // 2. Create a unique key for each line (rect + page)
                    let rect = line.bounds(for: page)
                    let key = "\(page.label ?? page.label ?? "")-\(rect.origin.x)-\(rect.origin.y)-\(rect.size.width)-\(rect.size.height)"
                    
                    if let existing = previewAnnotationsMap[key] {
                        // 2. If exists, remove from oldAnnotations and continue
                        oldAnnotations.removeValue(forKey: key)
                    } else {
                        // 3. If not exists, add annotation and to the map
                        let highlight = PDFAnnotation(bounds: rect, forType: .highlight, withProperties: nil)
                        highlight.color = highlightType.color()
                        page.addAnnotation(highlight)
                        previewAnnotationsMap[key] = highlight
                    }
                }
                // 4. Remove all annotations left in the oldAnnotations map
                for (_, annotation) in oldAnnotations {
                    annotation.page?.removeAnnotation(annotation)
                    previewAnnotationsMap = previewAnnotationsMap.filter { $0.value != annotation }
                }
            }
        case .ended:
            // Convert preview highlights to permanent, or recreate them as needed
            // Here we simply keep them, but you could update them if you wish
            previewAnnotationsMap.removeAll()
            longPressStartPage = nil
            longPressStartLocation = nil
            extractActionButton?.setNeedsUpdateConfiguration()
        default:
            // Cancel or clean up if needed
            previewAnnotationsMap.forEach { $1.page?.removeAnnotation($1) }
            previewAnnotationsMap.removeAll()
            longPressStartPage = nil
            longPressStartLocation = nil
        }
    }
    
    @objc
    private func handleUserDidTap(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: pdfView)
        guard let page = pdfView.page(for: location, nearest: true) else { return }
        let pdfCoordinate = pdfView.convert(location, to: page)
        if let annotation = page.annotation(at: pdfCoordinate) {
            hitOnAnnotation(annotation: annotation)
        }
    }
    
    @objc
    private func selectionChanged() {
        guard case let .highlight(lineType) = editingMode else { return }
        
        highlightSelection(color: lineType.color())
    }
    
    // MARK: - Action Methods
    
    private func hitOnAnnotation(annotation: PDFAnnotation) {
        guard let page = annotation.page,
              let annotationType = annotation.type,
              annotationType == "Highlight" || PDFAnnotationSubtype(rawValue: annotationType) == .highlight
        else { return }
        
        if case let .eraser = editingMode {
            page.removeAnnotation(annotation)
            extractActionButton?.setNeedsUpdateConfiguration()
            return
        }
        
        let menuInteraction = UIEditMenuInteraction(delegate: self)
        self.view.addInteraction(menuInteraction)
        let presentationPoint = CGPoint(x: annotation.bounds.minX + annotation.bounds.width / 2, y: annotation.bounds.minY)
        let location = self.view.convert(self.pdfView.convert(presentationPoint, from: page), from: self.pdfView)
        let menuConfiguration = UIEditMenuConfiguration(identifier: "removeHighlight", sourcePoint: location)
        self.selectedHighlight = annotation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.pdfView.documentView?.resignFirstResponder()
            self.pdfView.documentView?.endEditing(true)
            menuInteraction.presentEditMenu(with: menuConfiguration)
        }
    }
    
    private func highlightSelection(color: UIColor) {
        guard let selection = pdfView.currentSelection, let page = pdfView.currentPage else { return }

        // add a highlight annotation for the each line in the selection
        selection.selectionsByLine().forEach { selectionByLine in
            let annotation = PDFAnnotation(bounds: selectionByLine.bounds(for: page), forType: .highlight, withProperties: nil)
            annotation.color = color.withAlphaComponent(0.4)
            annotation.contents = selectionByLine.string
            page.addAnnotation(annotation)
        }
        pdfView.clearSelection()
        extractActionButton?.setNeedsUpdateConfiguration()
    }
    
    private func savePDF(outputURL: URL) -> Bool {
        let securityScoped = outputURL.startAccessingSecurityScopedResource()
        defer {
            if securityScoped {
                outputURL.stopAccessingSecurityScopedResource()
            }
        }
        return document.write(to: outputURL)
    }
}

// MARK: - UIEditMenuInteractionDelegate

extension PDFViewController: UIEditMenuInteractionDelegate {
    public func editMenuInteraction(_ interaction: UIEditMenuInteraction, menuFor configuration: UIEditMenuConfiguration, suggestedActions: [UIMenuElement]) -> UIMenu? {
        UIMenu(children: [
            UIAction(title: "Remove", attributes: .destructive) { [weak self] _ in
                guard let selectedHighlight = self?.selectedHighlight,
                      let page = selectedHighlight.page
                else { return }
                
                page.removeAnnotation(selectedHighlight)
                self?.selectedHighlight = nil
                self?.extractActionButton?.setNeedsUpdateConfiguration()
            }
        ])
    }
}

// MARK: - UIGestureRecognizerDelegate

extension PDFViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let tapRecognizer = otherGestureRecognizer as? UITapGestureRecognizer,
           self.view.gestureRecognizers?.contains(gestureRecognizer) ?? false &&
            tapRecognizer.numberOfTapsRequired == 1 &&
            (otherGestureRecognizer.view == self.pdfView)
        {
            otherGestureRecognizer.state = .cancelled
            return true
        }
        return false
    }
}

/// MARK: - Color Utility
/// A utility method to convert a hex color string to a UIColor instance.

extension PDFViewController {
    static func color(from hex: String) -> UIColor? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }
}

import SwiftUI
//let projectRoot = URL(fileURLWithPath: #file).pathComponents
//    .prefix(while: { $0 != "ios" }).joined(separator: "/").dropFirst()

#Preview {
    
    return Text("huy")
//    return SwiftUIHostedView {
//        try! PDFViewController(
//            pdfURL: URL(filePath: "\(projectRoot)/example/ios/Runner/Auld-Lang-Syne-highlighted.pdf"),
//            completionHandler: {_ in})
//    }
}

struct SwiftUIHostedView: UIViewRepresentable {
    typealias UIViewType = UIView
    
    let viewController: UIViewController
    
    init(_ viewController: () -> UIViewController) {
        self.viewController = viewController()
    }
    
    func makeUIView(context: Context) -> UIView {
        viewController.view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        viewController.view = uiView
    }
}
