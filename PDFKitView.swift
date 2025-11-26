import SwiftUI
import PDFKit

struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        print("DEBUG: makeUIView called for PDFKitView")
        
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(true)
        pdfView.backgroundColor = .white

        // Load document safely
        DispatchQueue.main.async {
            let doc = PDFDocument(url: url)
            if let doc = doc {
                print("DEBUG: Loaded PDF with \(doc.pageCount) pages.")
                pdfView.document = doc
            } else {
                print("DEBUG: ERROR - pdfView could NOT load document at \(url.path)")
            }
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        print("DEBUG: updateUIView called")
        // Only assign if needed
        if uiView.document == nil {
            let doc = PDFDocument(url: url)
            uiView.document = doc
        }
    }
}
