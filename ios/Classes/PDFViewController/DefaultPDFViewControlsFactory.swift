//
//  File.swift
//  PDFViewController
//
//  Created by Igor Fedorov on 14.06.2025.
//

import Foundation
import UIKit


struct DefaultPDFViewControlsFactory: PDFViewControlsFactory {
    func makeHighlightButton(highlightMeta: PDFViewController.HighlightMeta, action: @escaping () -> Void) -> UIButton {
        let button = makeButton(title: highlightMeta.title) { _ in
            action()
        }
        button.tintColor = highlightMeta.color
        
        return button
    }
    
    func makeRemoveHighlightModeButton(action: @escaping () -> Void) -> UIButton {
        makeButton(title: "✏️") { _ in action() }
    }
    
    func makeCloseButton(action: @escaping () -> Void) -> UIButton? {
        makeButton(title: "←") { _ in action() }
    }
    
    func makeSaveDocumentButton(action: @escaping () -> Void) -> UIButton? {
        makeButton(title: "Save") { _ in action() }
    }

    @MainActor
    private func makeButton(title: String, action: @escaping (UIAction) -> Void) -> UIButton {
        let button = UIButton(configuration: .filled())
        button.setTitle(title, for: .normal)
        button.configuration?.cornerStyle = .capsule
        button.addAction(UIAction { action($0) }, for: .touchUpInside)
        button.isEnabled = false
        return button
    }
}
