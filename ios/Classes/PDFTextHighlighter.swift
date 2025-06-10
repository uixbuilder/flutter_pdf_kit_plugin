//
//  PDFTextHighlighter.swift
//  PDFHighlightExtraction
//
//  Created by Igor Fedorov on 10.06.2025.
//

import Foundation
import PDFKit

class PDFTextHighlighter {
    func highlightTextInPdf(pdfURL: URL, textToHighlight: String) -> Bool {
        guard let pdfData = try? Data(contentsOf: pdfURL),
              let pdfDocument = PDFDocument(data: pdfData),
              let highlightedTextSelection = pdfDocument.findString(textToHighlight).first
        else {
            return false
        }

        var addedSomeHighlight: Bool = false
        highlightedTextSelection.selectionsByLine().forEach { selectionByLine in
            selectionByLine.pages.forEach { page in
                guard page.document == pdfDocument else {
                    assertionFailure("Invalid page")
                    return
                }
                
                let highlight = PDFAnnotation(bounds: selectionByLine.bounds(for: page),
                                              forType: .highlight,
                                              withProperties: nil)
                
                highlight.color = .yellow.withAlphaComponent(0.3)
                page.addAnnotation(highlight)
                addedSomeHighlight = true
            }
        }
        
        return addedSomeHighlight && pdfDocument.write(to: pdfURL)
    }
}
