import SwiftUI

struct LogBuiltPracticeView: View {
    @EnvironmentObject var appData: AppData
    @Environment(\.dismiss) var dismiss

    let template: BuiltPracticeTemplate

    // Analysis State
    @State private var isAnalyzing = false
    @State private var progress: Double = 0.0
    @State private var progressTimer: Timer? = nil
    @State private var aiPractice: AnalyzedPractice? = nil
    @State private var analysisError: String? = nil
    
    // Edit State (populated after analysis)
    @State private var editedDate: Date = Date()
    @State private var editedTime: Date = Date()
    @State private var editedDuration: Int = 0
    @State private var showSaveToast = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header: Template Info
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Log this practice")
                                .font(AppFont.pageTitle)
                                .foregroundStyle(.white)
                            
                            Text(template.title)
                                .font(AppFont.cardTitle)
                                .foregroundStyle(AppColor.accent)
                            
                            if let notes = template.notes {
                                Text(notes)
                                    .font(AppFont.body)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            
                            Divider().background(AppColor.border)
                            
                            HStack {
                                Image(systemName: "info.circle")
                                Text("Tap Analyze to process this template with AI.")
                            }
                            .font(AppFont.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    
                    // Action: Analyze
                    if aiPractice == nil && !isAnalyzing {
                        Button {
                            startAnalysis()
                        } label: {
                            Label("Analyze Practice", systemImage: "bolt.fill")
                                .font(AppFont.body.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColor.accent, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(Color.black)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Loading State
                    if isAnalyzing {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Analyzing template…")
                                    .font(AppFont.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.8))

                                ProgressView(value: progress)
                                    .progressViewStyle(.linear)
                                    .tint(AppColor.accent)
                                    .frame(height: 6)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    // Error State
                    if let err = analysisError {
                        GlassCard {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(AppColor.danger)
                                Text(err)
                                    .font(AppFont.body)
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    
                    // Result: Editable & Save
                    if let p = aiPractice {
                        analysisOutput(p)
                    }
                }
                .padding(AppLayout.padding)
            }
            
            // Toast Overlay
            if showSaveToast {
                VStack {
                    Spacer()
                    GlassCard {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColor.success)
                            Text("Practice Saved!")
                                .font(AppFont.body.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("Log Practice")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Analysis Logic
    
    private func startAnalysis() {
        isAnalyzing = true
        analysisError = nil
        aiPractice = nil
        startFakeProgress()
        
        // Generate text from template
        let textToAnalyze = template.commitStyleText(for: Date(), time: Date())
        
        AnalyzeService().analyze(text: textToAnalyze) { result in
            DispatchQueue.main.async {
                progressTimer?.invalidate()
                isAnalyzing = false
                progress = 1.0
                
                switch result {
                case .success(let practice):
                    // Populate edit fields
                    editedDate = Date()
                    editedTime = Date()
                    editedDuration = practice.durationMinutes
                    
                    // If duration is 0, try to estimate from template yards (rough guess: 2000yds ~ 60mins)
                    if editedDuration == 0 {
                        editedDuration = Int(Double(practice.distanceYards) / 30.0) // Very rough approx
                    }
                    
                    aiPractice = practice
                    Haptics.success()
                    
                case .failure(let err):
                    analysisError = err.description
                    Haptics.error()
                }
            }
        }
    }
    
    private func startFakeProgress() {
        progress = 0.0
        progressTimer?.invalidate()
        let totalDuration = 4.0 // Faster than image analysis
        let interval = 0.05
        let increment = (0.9 / (totalDuration / interval))
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            if progress < 0.9 {
                withAnimation { progress += increment }
            } else {
                timer.invalidate()
            }
        }
    }
    
    // MARK: - Output UI
    
    private func analysisOutput(_ p: AnalyzedPractice) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Practice Overview", systemImage: "list.bullet.rectangle.portrait")
                    .font(AppFont.cardTitle)
                    .foregroundStyle(.white)
                
                Divider().background(AppColor.border)

                DatePicker("Date", selection: $editedDate, displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .colorScheme(.dark)

                DatePicker("Time", selection: $editedTime, displayedComponents: [.hourAndMinute])
                    .datePickerStyle(.compact)
                    .colorScheme(.dark)

                HStack {
                    Image(systemName: "timer")
                    Stepper(value: $editedDuration, in: 0...600, step: 15) {
                        Text("Duration: \(editedDuration) min")
                            .font(AppFont.body)
                            .foregroundStyle(.white)
                            .monospacedDigit()
                    }
                }

                Text("Total Distance: \(p.distanceYards) yds")
                    .font(AppFont.body.bold())
                    .foregroundStyle(.white)
                
                if let tag = p.practiceTag {
                    Text("Focus: \(tag)")
                        .font(AppFont.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                ForEach(["Warmup", "Preset", "Main Set", "Post-Set", "Cooldown"], id: \.self) { key in
                    if let yds = p.sectionYards[key] {
                        Text("• \(key): \(yds) yds")
                            .font(AppFont.body)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                Button {
                    savePractice(p)
                } label: {
                    Label("Save Practice", systemImage: "tray.and.arrow.down.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Save Logic
    
    private func savePractice(_ p: AnalyzedPractice) {
        var finalPractice = p
        
        // Apply overrides
        finalPractice = AnalyzedPractice(
            id: p.id,
            date: ISO8601DateFormatter().string(from: editedDate),
            formattedText: p.formattedText,
            aiSummary: p.aiSummary,
            distanceYards: p.distanceYards,
            durationMinutes: editedDuration,
            sectionYards: p.sectionYards,
            strokePercentages: p.strokePercentages,
            aiTip: p.aiTip,
            timeOfDay: DateFormatter.localizedString(from: editedTime, dateStyle: .none, timeStyle: .short),
            practiceTag: p.practiceTag,
            recoverySuggestions: p.recoverySuggestions,
            title: p.title,
            intensitySummary: p.intensitySummary,
            insights: p.insights,
            recoveryPlan: p.recoveryPlan
        )
        
        // Generate PDF
        if let pdfURL = PracticeSheetPDFGenerator.generateSheetPDF(from: finalPractice.formattedText, practiceID: finalPractice.id) {
            appData.savePracticePDF(pdfURL, for: finalPractice.id)
        }
        
        // Save
        appData.addPractice(finalPractice)
        appData.recentlySavedPractice = finalPractice
        
        Haptics.success()
        withAnimation { showSaveToast = true }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            dismiss()
        }
    }
}
