//
//  PDFTextExtractor.swift
//  PDFHighlightExtraction
//
//  Created by Igor Fedorov on 01.06.2025.
//

import PDFKit


class PDFTextExtractor {
    
    func extractHighlightedText(from pdfURL: URL) -> [String] {
        var allHighlightedTexts: [String] = []
        
        // 1. Create a PDFDocument object.
        guard let pdfData = try? Data(contentsOf: pdfURL), let pdfDocument = PDFDocument(data: pdfData) else {
            // Your existing error handling for file existence and PDFDocument failure
            if FileManager.default.fileExists(atPath: pdfURL.path) {
                // Try reading raw data to see if it's accessible at all (for deeper diagnostics)
                do {
                    let fileData = try Data(contentsOf: pdfURL)
                    return ["Successfully read \(fileData.count) bytes from file."]
                } catch {
                    return ["ERROR: Failed to read raw data from file: \(String(describing: error))"]
                }
            }
            else {
                print("File DOES NOT EXIST at path: \(pdfURL.path)")
                return ["url does not exist"]
            }
        }

        // 2. Iterate through each page of the PDF.
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else {
                continue
            }
            
            // 3. Get all annotations on the current page.
            let annotations = page.annotations
            
            for annotation in annotations {
                
                // 4. Check if the annotation is a highlight and text is selectable.
                if let type = annotation.type,
                   type == "Highlight" || PDFAnnotationSubtype(rawValue: type) == .highlight,
                   let selection = page.selection(for: annotation.bounds)
                {
                    // 5. For highlight annotations, get the selection of the page that this annotation covers.
                    // The `quadrilateralPoints` define the bounding boxes of the highlighted text.
                    // We can approximate the selection from these points.
                    // A more robust way is to use the `selection(for: page)` method if available
                    // or iterate through text covered by annotation bounds.
                    
                    if let highlightedText = selection.string {
                        if !highlightedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            allHighlightedTexts.append(highlightedText.trimmingCharacters(in: .whitespacesAndNewlines))
                        }
                    }
                }
            }
        }
        return allHighlightedTexts
    }
}
