//
//  PDFTextExtractor.swift
//  PDFHighlightExtraction
//
//  Created by Igor Fedorov on 01.06.2025.
//

import PDFKit

    
class PDFTextExtractor {
    func extractHighlightedText(from pdfURL: URL) -> [[String: Any]] {
        var allHighlights: [[String: Any]] = []
        
        guard let pdfData = try? Data(contentsOf: pdfURL), let pdfDocument = PDFDocument(data: pdfData) else {
            return []
        }

        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            let annotations = page.annotations
            for annotation in annotations {
                if let type = annotation.type,
                   type == "Highlight" || PDFAnnotationSubtype(rawValue: type) == .highlight,
                   let selection = page.selection(for: annotation.bounds),
                   let highlightedText = selection.string?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !highlightedText.isEmpty {
                    
                    // Get color as hex string if available
                    let ciColor = CIColor(color: annotation.color)
                    let r = Int(ciColor.red * 255)
                    let g = Int(ciColor.green * 255)
                    let b = Int(ciColor.blue * 255)
                    let colorHex = String(format: "#%02X%02X%02X", r, g, b)
                    
                    // Get bounding rect in PDF coordinates
                    let bounds = annotation.bounds
                    let rectMap: [String: CGFloat] = [
                        "left": bounds.origin.x,
                        "top": bounds.origin.y,
                        "right": bounds.origin.x + bounds.size.width,
                        "bottom": bounds.origin.y + bounds.size.height
                    ]
                    
                    let highlightDict: [String: Any] = [
                        "text": highlightedText,
                        "color": colorHex as Any,
                        "rect": rectMap
                    ]
                    allHighlights.append(highlightDict)
                }
            }
        }
        return allHighlights
    }
}
