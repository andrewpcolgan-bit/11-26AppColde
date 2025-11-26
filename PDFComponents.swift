import SwiftUI
import PDFKit

struct PDFViewer: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var document: PDFDocument? = nil

    var body: some View {
        NavigationStack {
            Group {
                if let doc = document {
                    PDFKitRepresentedView(document: doc)
                        .ignoresSafeArea(edges: .bottom)
                } else {
                    ProgressView("Loading PDF…")
                }
            }
            .navigationTitle(url.deletingPathExtension().lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button {
                        printPDF(at: url)
                    } label: {
                        Image(systemName: "printer")
                    }
                    .accessibilityLabel("Print")
                }
            }
        }
        .onAppear { document = PDFDocument(url: url) }
    }

    private func printPDF(at url: URL) {
        guard let data = try? Data(contentsOf: url) else { return }
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = url.lastPathComponent

        let controller = UIPrintInteractionController.shared
        controller.printInfo = info
        controller.showsNumberOfCopies = true
        controller.printingItem = data
        controller.present(animated: true, completionHandler: nil)
    }
}

struct PDFKitRepresentedView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let v = PDFView()
        v.autoScales = true
        v.displayMode = .singlePageContinuous
        v.displayDirection = .vertical
        v.backgroundColor = .systemBackground
        v.document = document
        return v
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = document
    }
}

struct PDFThumbnailView: View {
    let url: URL
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .overlay { ProgressView() }
            }
        }
        .task {
            image = await renderThumbnail(from: url)
        }
    }

    private func renderThumbnail(from url: URL) async -> UIImage? {
        await withCheckedContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                guard
                    let doc = PDFDocument(url: url),
                    let page = doc.page(at: 0)
                else { return cont.resume(returning: nil) }

                let rect = page.bounds(for: .mediaBox)
                let scale: CGFloat = 0.4
                let size = CGSize(width: rect.width * scale, height: rect.height * scale)
                let img = page.thumbnail(of: size, for: .mediaBox)
                cont.resume(returning: img)
            }
        }
    }
}
