import SwiftUI

// MARK: - Draft Model
struct AnalyzedPracticeDraft {
    var title: String
    var date: Date
    var durationMinutes: Int
    var tag: String
    var notes: String
    
    // Read-only from analysis
    let totalYards: Int
    let sections: [String: Int]
    let originalPractice: AnalyzedPractice
}

struct AnalyzeView: View {
    @EnvironmentObject var appData: AppData
    @Environment(\.dismiss) private var dismiss
    
    let image: UIImage
    
    // MARK: - State
    enum ViewState: Equatable {
        case analyzing
        case review
        case error(String)
    }
    
    @State private var viewState: ViewState = .analyzing
    @State private var progress: Double = 0.0
    @State private var draft: AnalyzedPracticeDraft?
    @State private var showZoomedImage = false
    @State private var isSaving = false
    
    // Services
    private let service = AnalyzeService()
    private let ocrService = OCRService()
    
    // Animation Timer
    @State private var timer: Timer?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                switch viewState {
                case .analyzing:
                    LoadingView(image: image, progress: progress)
                        .transition(.opacity)
                case .review:
                    if let draft = draft {
                        ReviewView(
                            draft: Binding(
                                get: { self.draft! },
                                set: { self.draft = $0 }
                            ),
                            image: image,
                            onSave: savePractice,
                            onDiscard: { dismiss() },
                            showZoomedImage: $showZoomedImage,
                            isSaving: isSaving
                        )
                        .transition(.opacity)
                    }
                case .error(let message):
                    ErrorView(
                        image: image,
                        message: message,
                        onRetake: { dismiss() },
                        onTryAnyway: tryAnyway
                    )
                }
            }
            .navigationTitle(viewState == .review ? "Review Practice" : "Analyze Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
            }
            .onAppear {
                if case .analyzing = viewState {
                    startAnalysis()
                }
            }
            .sheet(isPresented: $showZoomedImage) {
                NavigationStack {
                    ZoomableImageView(image: image)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") { showZoomedImage = false }
                            }
                        }
                }
            }
        }
    }
    
    // MARK: - Logic
    
    private func startAnalysis() {
        // Start fake progress
        progress = 0.0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if self.progress < 0.9 {
                self.progress += 0.005 // Slowly increment to 90% over ~18s
            }
        }
        
        // Step 1: Extract text using OCR
        ocrService.extractText(from: image) { text in
            DispatchQueue.main.async {
                guard let extractedText = text, !extractedText.isEmpty else {
                    self.timer?.invalidate()
                    self.viewState = .error("Could not extract text from image. Please try a clearer photo.")
                    return
                }
                
                // Step 2: Analyze the extracted text
                self.service.analyze(text: extractedText) { result in
                    DispatchQueue.main.async {
                        self.timer?.invalidate()
                        
                        switch result {
                        case .success(let practice):
                            // Jump to 100%
                            withAnimation(.easeOut(duration: 0.5)) {
                                self.progress = 1.0
                            }
                            
                            // Delay slightly to show 100% then switch
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                self.prepareDraft(from: practice)
                                withAnimation {
                                    self.viewState = .review
                                }
                            }
                            
                        case .failure(let error):
                            self.viewState = .error(error.description)
                        }
                    }
                }
            }
        }
    }
    
    private func prepareDraft(from practice: AnalyzedPractice) {
        let fmt = ISO8601DateFormatter()
        fmt.timeZone = .current
        let date = fmt.date(from: practice.date) ?? Date()
        
        // Title Logic: "Monday Morning, Nov 24"
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let timeOfDay = hour < 12 ? "Morning" : "Afternoon"
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE" // Monday
        let dayString = dayFormatter.string(from: date)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d" // Nov 24
        let dateString = dateFormatter.string(from: date)
        
        let defaultTitle = "\(dayString) \(timeOfDay), \(dateString)"
        let title = practice.title ?? defaultTitle
        
        // Focus Detection Logic
        let validTags = ["Easy", "Aerobic", "Threshold", "Race Pace", "Recovery", "Kick / Drill", "Taper"]
        var detectedTag = "Unlabeled"
        
        if let backendTag = practice.practiceTag {
            // 1. Try exact match
            if validTags.contains(backendTag) {
                detectedTag = backendTag
            } else {
                // 2. Try partial match (case-insensitive)
                let lowerBackend = backendTag.lowercased()
                if let match = validTags.first(where: { lowerBackend.contains($0.lowercased()) }) {
                    detectedTag = match
                }
            }
        }
        
        self.draft = AnalyzedPracticeDraft(
            title: title,
            date: date,
            durationMinutes: practice.durationMinutes > 0 ? practice.durationMinutes : 60,
            tag: detectedTag,
            notes: practice.aiSummary,
            totalYards: practice.distanceYards,
            sections: practice.sectionYards,
            originalPractice: practice
        )
    }
    
    private func tryAnyway() {
        // Fallback: Create a blank/basic practice
        let practice = AnalyzedPractice(
            id: UUID().uuidString,
            date: ISO8601DateFormatter().string(from: Date()),
            formattedText: "",
            aiSummary: "Manual entry from failed analysis.",
            distanceYards: 0,
            durationMinutes: 60,
            sectionYards: [:],
            strokePercentages: [:],
            aiTip: nil,
            timeOfDay: nil,
            practiceTag: nil,
            recoverySuggestions: nil,
            title: nil,
            intensitySummary: nil,
            insights: nil,
            recoveryPlan: nil
        )
        prepareDraft(from: practice)
        viewState = .review
    }
    
    private func savePractice() {
        guard let draft = draft else { return }
        isSaving = true
        
        // Convert draft back to AnalyzedPractice
        let fmt = ISO8601DateFormatter()
        fmt.timeZone = .current
        
        let finalPractice = AnalyzedPractice(
            id: draft.originalPractice.id,
            date: fmt.string(from: draft.date),
            formattedText: draft.originalPractice.formattedText,
            aiSummary: draft.notes,
            distanceYards: draft.totalYards,
            durationMinutes: draft.durationMinutes,
            sectionYards: draft.sections,
            strokePercentages: draft.originalPractice.strokePercentages,
            aiTip: draft.originalPractice.aiTip,
            timeOfDay: draft.originalPractice.timeOfDay,
            practiceTag: draft.tag,
            recoverySuggestions: draft.originalPractice.recoverySuggestions,
            title: draft.title,
            intensitySummary: draft.originalPractice.intensitySummary,
            insights: draft.originalPractice.insights,
            recoveryPlan: draft.originalPractice.recoveryPlan
        )
        
        appData.addPractice(finalPractice)
        appData.savePracticeImage(image, for: finalPractice.id)
        
        // Auto-generate PDF
        DispatchQueue.global(qos: .userInitiated).async {
             _ = PracticeSheetPDFGenerator.generateSheetPDF(from: finalPractice.formattedText, practiceID: finalPractice.id)
        }
        
        // Simulate save delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSaving = false
            dismiss()
        }
    }
}

// MARK: - Subviews

struct LoadingView: View {
    let image: UIImage
    let progress: Double
    
    var body: some View {
        VStack(spacing: 24) {
            GlassCard {
                ZStack(alignment: .bottomTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Text("Captured sheet")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(8)
                        .background(.black.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(8)
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                Text("Analyzing practice...")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                
                Text(progress > 0.5 ? "Extracting sets, strokes, and yardage." : "Reading text from image...")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                
                // Custom Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(Color.appAccent)
                            .frame(width: geo.size.width * progress, height: 8)
                            .animation(.linear, value: progress)
                    }
                }
                .frame(height: 8)
                .frame(maxWidth: 240)
            }
            
            Spacer()
            
            Text("You’ll be able to edit the details before saving.")
                .font(.caption)
                .foregroundStyle(Color.textMuted)
                .padding(.bottom)
        }
        .padding(.top)
    }
}

struct ErrorView: View {
    let image: UIImage
    let message: String
    let onRetake: () -> Void
    let onTryAnyway: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            GlassCard {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .opacity(0.6)
            }
            .padding(.horizontal)
            
            VStack(spacing: 8) {
                Text("We couldn’t read that sheet.")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.textPrimary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            HStack(spacing: 16) {
                Button(action: onRetake) {
                    Text("Retake Photo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: onTryAnyway) {
                    Text("Try Anyway")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 40)
    }
}

struct ReviewView: View {
    @Binding var draft: AnalyzedPracticeDraft
    let image: UIImage
    let onSave: () -> Void
    let onDiscard: () -> Void
    @Binding var showZoomedImage: Bool
    let isSaving: Bool
    
    @State private var isSetsExpanded = false
    
    let tags = ["Easy", "Aerobic", "Threshold", "Race Pace", "Recovery", "Kick / Drill", "Taper"]
    let sectionOrder = ["Warmup", "Preset", "Main Set", "Post-Set", "Cooldown"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image Card
                GlassCard {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                        
                        Button(action: { showZoomedImage = true }) {
                            Image(systemName: "plus.magnifyingglass")
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(.black.opacity(0.4))
                                .clipShape(Circle())
                        }
                        .padding(8)
                        
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("Captured sheet")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .padding(6)
                                    .background(.black.opacity(0.4))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                        .padding(8)
                    }
                }
                .padding(.horizontal)
                
                // Status Banner
                VStack(spacing: 4) {
                    Text("Analysis Complete!")
                        .font(.headline)
                        .foregroundStyle(Color.appAccent)
                    Text("Double-check the details and make any edits before saving.")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                
                // Metrics
                HStack(spacing: 12) {
                    MetricTile(label: "Total Yards", value: "\(draft.totalYards) yds")
                    
                    // Editable Duration Tile
                    Button {
                        // Focus duration picker? 
                        // For now just a visual tile, editing is in the form below
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text("Duration")
                                    .font(AppFont.captionMuted)
                                    .foregroundStyle(Color.textMuted)
                                Image(systemName: "pencil")
                                    .font(.caption2)
                                    .foregroundStyle(Color.textMuted)
                            }
                            Text("\(draft.durationMinutes) min")
                                .font(AppFont.bodyBold)
                                .foregroundStyle(Color.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.horizontal)
                
                // Editable Form
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        // Title
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Title", systemImage: "pencil.line")
                                .font(.caption)
                                .foregroundStyle(Color.textMuted)
                            TextField("Practice Title", text: $draft.title)
                                .textFieldStyle(.plain)
                                .font(.body)
                                .padding(8)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                        }
                        
                        // Date & Time
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Date", systemImage: "calendar")
                                    .font(.caption)
                                    .foregroundStyle(Color.textMuted)
                                DatePicker("", selection: $draft.date, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Time", systemImage: "clock")
                                    .font(.caption)
                                    .foregroundStyle(Color.textMuted)
                                DatePicker("", selection: $draft.date, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                        }
                        
                        // Duration Slider/Stepper
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Duration (min)", systemImage: "timer")
                                .font(.caption)
                                .foregroundStyle(Color.textMuted)
                            HStack {
                                Slider(value: Binding(
                                    get: { Double(draft.durationMinutes) },
                                    set: { draft.durationMinutes = Int($0) }
                                ), in: 15...180, step: 5)
                                Text("\(draft.durationMinutes)m")
                                    .font(.subheadline.monospacedDigit())
                                    .frame(width: 50)
                            }
                        }
                        
                        // Tags
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Focus", systemImage: "tag")
                                .font(.caption)
                                .foregroundStyle(Color.textMuted)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(tags, id: \.self) { tag in
                                        TagPill(
                                            text: tag,
                                            isSelected: draft.tag == tag
                                        )
                                        .onTapGesture {
                                            draft.tag = tag
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Notes", systemImage: "text.alignleft")
                                .font(.caption)
                                .foregroundStyle(Color.textMuted)
                            
                            TextEditor(text: $draft.notes)
                                .frame(minHeight: 80)
                                .scrollContentBackground(.hidden)
                                .padding(4)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                .padding(.horizontal)
                
                // Sets & Yardage (Collapsible)
                VStack(spacing: 0) {
                    Button(action: { withAnimation { isSetsExpanded.toggle() } }) {
                        HStack {
                            Text("Sets & Yardage")
                                .font(.headline)
                                .foregroundStyle(Color.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .rotationEffect(.degrees(isSetsExpanded ? 90 : 0))
                                .foregroundStyle(Color.textSecondary)
                        }
                        .padding()
                        .background(Color.white.opacity(0.03))
                    }
                    
                    if isSetsExpanded {
                        VStack(spacing: 12) {
                            ForEach(sectionOrder, id: \.self) { key in
                                if let value = draft.sections[key], value > 0 {
                                    HStack {
                                        Text(key)
                                            .foregroundStyle(Color.textSecondary)
                                        Spacer()
                                        Text("\(value) yds")
                                            .font(.subheadline.bold())
                                            .foregroundStyle(Color.textPrimary)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.02))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                // Actions
                VStack(spacing: 16) {
                    Button(action: onSave) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isSaving ? "Saving..." : "Save Practice")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appAccent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isSaving)
                    
                    Button("Discard", role: .destructive, action: onDiscard)
                        .foregroundStyle(Color.red.opacity(0.8))
                }
                .padding()
            }
            .padding(.bottom, 20)
        }
    }
}

struct ZoomableImageView: View {
    let image: UIImage
    
    var body: some View {
        // Simple zoomable image implementation
        // For now just a scrollview with the image
        ScrollView([.horizontal, .vertical]) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        }
        .background(Color.black)
    }
}
