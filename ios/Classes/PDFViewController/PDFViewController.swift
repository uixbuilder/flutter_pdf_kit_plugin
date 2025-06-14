import Foundation
import PDFKit
import UIKit

/// A view controller that provides interactive PDF viewing and annotation capabilities.
///
/// `PDFViewController` enables users to view, highlight, and remove highlights from PDF documents.
/// The controller relies on a control factory for all UI buttons, and exposes completion handlers
/// for save and close events.
public class PDFViewController: UIViewController, PDFViewDelegate {
    /// A tuple describing a highlight style and tag.
    public typealias HighlightMeta = (tag: String, title: String, color: UIColor)
    /// A handler called on completion of save/close events.
    public typealias CompletionHandler = (_ pdfHighlighted: Bool) -> Void
    
    private let pdfView = PDFView()
    private let document: PDFDocument
    private var highlightButtons: [UIButton]?
    private var saveDocumentButton: UIButton?
    private var closeButton: UIButton?
    private var removeHighlightModeButton: UIButton?
    private let controlsFactory: PDFViewControlsFactory
    
    /// A Boolean value indicating whether the controller is in remove highlight mode.
    ///
    /// When set to `true`, tapping a highlight annotation will remove it instead of showing options.
    public var removeHighlightMode: Bool = false {
        didSet {
            removeHighlightModeButton?.tintColor = removeHighlightMode ? .systemBlue : .systemBlue.withAlphaComponent(0.5)
        }
    }
    
    /// A Boolean value indicating whether the document has unsaved changes.
    ///
    /// When set, it updates the enabled state of the save button accordingly.
    public var hasChanges: Bool = false {
        didSet {
            saveDocumentButton?.isEnabled = hasChanges
        }
    }
    
    private let highlightMeta: [HighlightMeta]
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
        highlightMeta: [HighlightMeta],
        controlFactory: PDFViewControlsFactory,
        completionHandler: @escaping CompletionHandler
    ) throws {
        self.highlightMeta = highlightMeta
        self.controlsFactory = controlFactory
        if let document = PDFDocument(url: pdfURL) {
            self.document = document
            super.init(nibName: nil, bundle: nil)
            self.saveDocumentButton = controlFactory.makeSaveDocumentButton { [weak self] in
                self?.hasChanges = self?.savePDF(outputURL: pdfURL) == false
                completionHandler(self?.hasChanges ?? false)
            }
            self.closeButton = controlFactory.makeCloseButton {
                completionHandler(false)
            }
        }
        else {
            throw NSError(domain: CocoaError.errorDomain, code: CocoaError.fileReadCorruptFile.rawValue)
        }
    }
    
    /// Initializes a new instance from a decoder.
    /// - Parameter coder: The decoder to initialize from.
    /// - Note: This initializer is not implemented and will cause a runtime error if called.
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        attachPDFView()
        
        attachHighlightControls()
        
        attachCloseButtonIfNeeded()
        
        attachSaveButtonIfNeeded()
        
        attachRemoveHighlightModeButton(to: saveDocumentButton?.bottomAnchor ?? pdfView.safeAreaLayoutGuide.topAnchor)
        
        setupObserving()
    }
    
    // MARK: - UI construction Methods
    
    private func attachRemoveHighlightModeButton(to upperAnchor: NSLayoutYAxisAnchor) {
        let removeHighlightModeButton = self.controlsFactory.makeRemoveHighlightModeButton { [weak self] in
            self?.removeHighlightMode.toggle()
        }
        removeHighlightModeButton.isEnabled = true
        removeHighlightModeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(removeHighlightModeButton)
        NSLayoutConstraint.activate([
            view.trailingAnchor.constraint(equalTo: removeHighlightModeButton.trailingAnchor, constant: 20),
            upperAnchor.constraint(equalTo: removeHighlightModeButton.topAnchor, constant: -20)
        ])
        
        self.removeHighlightModeButton = removeHighlightModeButton
        removeHighlightMode = false
    }
    
    private func attachSaveButtonIfNeeded() {
        guard let saveDocumentButton else { return }
        saveDocumentButton.tintColor = .systemBlue
        saveDocumentButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveDocumentButton)
        NSLayoutConstraint.activate([
            view.trailingAnchor.constraint(equalTo: saveDocumentButton.trailingAnchor, constant: 20),
            pdfView.safeAreaLayoutGuide.topAnchor.constraint(equalTo: saveDocumentButton.topAnchor, constant: -20)
        ])
    }
    
    private func attachCloseButtonIfNeeded() {
        guard let closeButton else { return }
        closeButton.isEnabled = true
        closeButton.tintColor = .systemBlue
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -20),
            pdfView.safeAreaLayoutGuide.topAnchor.constraint(equalTo: closeButton.topAnchor, constant: -20)
        ])
    }
    
    private func attachHighlightControls() {
        let highlightControls = highlightMeta.map { props in
            let button = self.controlsFactory.makeHighlightButton(highlightMeta: props) { [weak self] in
                self?.highlightSelection(color: props.color, tag: props.tag)
            }
            button.tintColor = props.color
            return button
        }
        
        let stack = UIStackView(arrangedSubviews: highlightControls)
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(stack)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(lessThanOrEqualTo: stack.leadingAnchor),
            view.trailingAnchor.constraint(greaterThanOrEqualTo: stack.trailingAnchor),
            view.centerXAnchor.constraint(equalTo: stack.centerXAnchor),
            pdfView.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: stack.bottomAnchor, constant: 20)
        ])
        
        highlightButtons = highlightControls
    }
    
    private func attachPDFView() {
        pdfView.document = document
        view.addSubview(pdfView)
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.topAnchor.constraint(equalTo: view.topAnchor),
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
        
        
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleUserDidTap))
        tapRecognizer.delegate = self
        view.addGestureRecognizer(tapRecognizer)
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
        highlightButtons?.forEach {
            $0.isEnabled = pdfView.currentSelection != nil
        }
    }
    
    // MARK: - Action Methods
    
    private func hitOnAnnotation(annotation: PDFAnnotation) {
        guard let page = annotation.page,
              let annotationType = annotation.type,
              annotationType == "Highlight" || PDFAnnotationSubtype(rawValue: annotationType) == .highlight
        else { return }
        
        if removeHighlightMode {
            page.removeAnnotation(annotation)
            hasChanges = true
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
    
    private func highlightSelection(color: UIColor, tag: String) {
        guard let selection = pdfView.currentSelection, let page = pdfView.currentPage else { return }

        // add a highlight annotation for the each line in the selection
        selection.selectionsByLine().forEach { selectionByLine in
            let annotation = PDFAnnotation(bounds: selectionByLine.bounds(for: page), forType: .highlight, withProperties: nil)
            annotation.color = color.withAlphaComponent(0.4)
            annotation.setValue(tag, forAnnotationKey: PDFAnnotationKey.name)
            page.addAnnotation(annotation)
        }
        pdfView.clearSelection()
        self.hasChanges = true
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
                self?.hasChanges = true
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