//
//  PDFViewControlsFactory.swift
//  PDFViewController
//
//  Created by Igor Fedorov on 14.06.2025.
//

import UIKit


/// A protocol for creating controls (such as buttons) for the PDF viewer UI.
///
/// Implementations of this protocol are responsible for providing
/// the custom UI controls used within `PDFViewController`, such as
/// highlight action buttons, mode toggles, and save/close controls.
public protocol PDFViewControlsFactory {
    /// Creates a highlight button for a particular highlight type.
    ///
    /// - Parameters:
    ///   - highlightMeta: The highlight metadata describing tag, title, and color.
    ///   - action: A closure to be called when the button is tapped.
    /// - Returns: A configured UIButton instance.
    @MainActor
    func makeHighlightButton(highlightMeta: PDFViewController.HighlightMeta, action: @escaping () -> Void) -> UIButton
    
    /// Creates a button for toggling remove highlight mode.
    ///
    /// - Parameter action: A closure to be called when the button is tapped.
    /// - Returns: A configured UIButton instance.
    @MainActor
    func makeRemoveHighlightModeButton(action: @escaping () -> Void) -> UIButton
    
    /// Creates an optional button for saving document changes.
    ///
    /// - Parameter action: A closure to be called when the button is tapped.
    /// - Returns: A configured UIButton instance, or `nil` to omit the control.
    @MainActor
    func makeSaveDocumentButton(action: @escaping () -> Void) -> UIButton?
    
    /// Creates an optional button for closing the viewer.
    ///
    /// - Parameter action: A closure to be called when the button is tapped.
    /// - Returns: A configured UIButton instance, or `nil` to omit the control.
    @MainActor
    func makeCloseButton(action: @escaping () -> Void) -> UIButton?
}

extension PDFViewControlsFactory {
    func makeSaveDocumentButton(action: @escaping () -> Void) -> UIButton? { nil }
    func makeCloseButton(action: @escaping () -> Void) -> UIButton? { nil }
}

