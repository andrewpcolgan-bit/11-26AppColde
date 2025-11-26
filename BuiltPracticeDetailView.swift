import SwiftUI
import PDFKit

struct BuiltPracticeDetailView: View {
    @EnvironmentObject var appData: AppData
    let template: BuiltPracticeTemplate
    
    @State private var generatedPDFURL: URL?
    @State private var pdfDocument: PDFDocument?
    @State private var isGenerating = true
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Card
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(template.title)
                                .font(AppFont.pageTitle)
                                .foregroundStyle(.white)
                            
                            if let notes = template.notes {
                                Text(notes)
                                    .font(AppFont.body)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            
                            HStack {
                                Text("Created \(template.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                if let pool = template.poolInfo {
                                    Text("• \(pool)")
                                }
                                Spacer()
                                Text("Total: \(template.totalYards) yds")
                                    .font(AppFont.body.bold())
                                    .foregroundStyle(AppColor.accent)
                            }
                            .font(AppFont.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    
                    // PDF Preview Card
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Preview", systemImage: "doc.text")
                                    .font(AppFont.cardTitle)
                                    .foregroundStyle(.white)
                                Spacer()
                                
                                if let url = generatedPDFURL {
                                    ShareLink(item: url) {
                                        Label("Share PDF", systemImage: "square.and.arrow.up")
                                            .font(AppFont.caption.weight(.semibold))
                                            .foregroundStyle(AppColor.accent)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(AppColor.accent.opacity(0.1), in: Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            Divider().background(AppColor.border)
                            
                            if let doc = pdfDocument {
                                PDFKitRepresentedView(document: doc)
                                    .frame(height: 400)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1)))
                            } else if isGenerating {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(.white)
                                    Spacer()
                                }
                                .frame(height: 200)
                            } else {
                                Text("Could not generate PDF preview.")
                                    .font(AppFont.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                                    .frame(height: 100)
                            }
                        }
                    }
                }
                .padding(AppLayout.padding)
            }
            
            // Footer
            VStack(spacing: 12) {
                NavigationLink(value: BuilderDestination.log(template)) {
                    Text("Log this practice")
                        .font(AppFont.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColor.accent, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(Color.black)
                }
                .buttonStyle(.plain)
                
                NavigationLink(value: BuilderDestination.build(.edit(template))) {
                    Text("Edit template")
                        .font(AppFont.body)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(AppLayout.padding)
            .background(AppColor.background)
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("Practice Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            generatePDF()
        }
    }
    
    private func generatePDF() {
        isGenerating = true
        // Run on background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            let text = template.commitStyleText(for: Date(), time: Date())
            if let url = PracticeSheetPDFGenerator.generateSheetPDF(from: text, practiceID: template.id.uuidString) {
                let doc = PDFDocument(url: url)
                DispatchQueue.main.async {
                    self.generatedPDFURL = url
                    self.pdfDocument = doc
                    self.isGenerating = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isGenerating = false
                }
            }
        }
    }
}
