import SwiftUI
import Charts
import PDFKit

struct PracticeDetailScreen: View {
    @EnvironmentObject var appData: AppData
    let practice: AnalyzedPractice // Keep this for initial value, but use mutablePractice for display
    
    @State private var mutablePractice: AnalyzedPractice // New state variable to hold the potentially modified practice
    
    init(practice: AnalyzedPractice) {
        self.practice = practice // Assign the initial practice to the 'let' property
        var mutable = practice
        mutable.ensureRecoveryPlan() // Apply the recovery plan logic
        _mutablePractice = State(initialValue: mutable) // Initialize the @State variable
    }
    
    @State private var isEditing = false
    @State private var editedDate = Date()
    @State private var editedDuration = 0
    @State private var editedTimeOfDay = "AM"
    
    // PDF viewer state
    @State private var selectedPDFURL: URL? = nil
    @State private var isGeneratingPDF = false
    @State private var pdfThumbnail: UIImage? = nil
    @State private var showShareSheet = false
    
    // Recovery Plan state
    @State private var showQuickRecovery = true // Toggle between Quick and Full recovery plans
    
    // Recovery template sheets
    @State private var showSaveTemplateSheet = false
    @State private var showApplyTemplateSheet = false

    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Header: Overview
                    headerCard
                    
                    // 2. PDF Preview (High Priority)
                    pdfPreviewCard
                    
                    // 3. Highlights (New)
                    highlightsCard
                    
                    // 4. Effort Mix & Work/Recovery (New)
                    effortMixCard
                    
                    // 5. Section Breakdown
                    if !practice.sectionYards.isEmpty {
                        sectionBreakdownCard
                    }
                    
                    // 6. Stroke Mix
                    strokeMixCard
                    
                    // 7. AI Summary & Tip
                    if practice.aiSummary != nil || practice.aiTip != nil {
                        coachNotesCard
                    }
                    
                    // 8. Recovery Plan (replaces old Recovery Suggestions)
                    recoveryPlanCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Practice Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    if let d = ISO8601DateFormatter().date(from: practice.date) {
                        editedDate = d
                    }
                    editedDuration = practice.durationMinutes
                    editedTimeOfDay = practice.timeOfDay ?? "AM"
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditPracticeSheet(
                practice: practice,
                date: $editedDate,
                duration: $editedDuration,
                timeOfDay: $editedTimeOfDay,
                onSave: { newDate, newDuration, newTimeOfDay in
                    updatePractice(newDate: newDate, newDuration: newDuration, newTimeOfDay: newTimeOfDay)
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(item: Binding(
            get: { selectedPDFURL.map { IdentifiableURL(url: $0) } },
            set: { selectedPDFURL = $0?.url }
        )) { item in
            PDFViewer(url: item.url)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [appData.pdfURL(for: practice.id)])
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSaveTemplateSheet) {
            if let plan = mutablePractice.recoveryPlan {
                SaveTemplateSheet(sourcePractice: mutablePractice, recoveryPlan: plan)
                    .environmentObject(appData)
            }
        }
        .sheet(isPresented: $showApplyTemplateSheet) {
            RecoveryLibraryView(isPickerMode: true) { template in
                applyTemplate(template)
            }
            .environmentObject(appData)
        }
    }
    
    // MARK: - 1. Header Card
    private var headerCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // Title Row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formattedPracticeTitle)
                            .font(AppFont.pageTitle)
                            .foregroundStyle(Color.textPrimary)
                        
                        Text(dateAndTimeText)
                            .font(AppFont.subtitle)
                            .foregroundStyle(Color.textSecondary)
                    }
                    Spacer()
                    if let tag = practice.practiceTag {
                        TagPill(text: tag, isSelected: true)
                    }
                }
                
                Divider().overlay(Color.white.opacity(0.1))
                
                // Metrics
                HStack(spacing: 12) {
                    MetricTile(label: "Total Distance", value: "\(practice.distanceYards) yds")
                    MetricTile(label: "Duration", value: formatDuration(practice.durationMinutes))
                    
                    // Pace Estimate (if possible) or Section Count
                    if practice.durationMinutes > 0 && practice.distanceYards > 0 {
                        let pace = Double(practice.durationMinutes * 60) / (Double(practice.distanceYards) / 100.0)
                        let min = Int(pace) / 60
                        let sec = Int(pace) % 60
                        let paceStr = String(format: "%d:%02d/100", min, sec)
                        MetricTile(label: "Avg Pace", value: paceStr)
                    } else {
                        MetricTile(label: "Sections", value: "\(practice.sectionYards.count)")
                    }
                }
            }
        }
    }
    
    // MARK: - 2. Section Breakdown
    private var sectionBreakdownCard: some View {
        let sectionOrder = ["Warmup", "Preset", "Main Set", "Post-Set", "Cooldown"]
        let orderedSections = practice.sectionYards.sorted { a, b in
            let i1 = sectionOrder.firstIndex(where: { $0.caseInsensitiveCompare(a.key) == .orderedSame }) ?? Int.max
            let i2 = sectionOrder.firstIndex(where: { $0.caseInsensitiveCompare(b.key) == .orderedSame }) ?? Int.max
            return i1 < i2
        }
        
        return GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Section Breakdown")
                    .font(AppFont.cardTitle)
                    .foregroundStyle(Color.textPrimary)
                
                // Bar Chart Visualization
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        ForEach(orderedSections, id: \.key) { section in
                            if section.value > 0 {
                                Rectangle()
                                    .fill(sectionColor(for: section.key))
                                    .frame(width: geo.size.width * (Double(section.value) / Double(practice.distanceYards)))
                            }
                        }
                    }
                }
                .frame(height: 8)
                .clipShape(Capsule())
                
                // Table
                VStack(spacing: 12) {
                    ForEach(orderedSections, id: \.key) { section in
                        if section.value > 0 {
                            HStack {
                                Circle()
                                    .fill(sectionColor(for: section.key))
                                    .frame(width: 8, height: 8)
                                Text(section.key)
                                    .font(AppFont.body)
                                    .foregroundStyle(Color.textPrimary)
                                Spacer()
                                Text("\(section.value) yds")
                                    .font(AppFont.bodyBold)
                                    .foregroundStyle(Color.textPrimary)
                                Text(percentage(section.value))
                                    .font(AppFont.captionMuted)
                                    .foregroundStyle(Color.textMuted)
                                    .frame(width: 40, alignment: .trailing)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 3. Stroke Mix
    private var strokeMixCard: some View {
        let mix = strokeYardsForPractice(practice)
        let totalYards = mix.map(\.value).reduce(0, +)
        let chartData = mix.map { (key: $0.key, value: $0.value) }.sorted { $0.value > $1.value }
        
        return GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Stroke Mix")
                        .font(AppFont.cardTitle)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Text("\(totalYards) yds total")
                        .font(AppFont.captionMuted)
                        .foregroundStyle(Color.textMuted)
                }
                
                if mix.isEmpty {
                    Text("No stroke data available.")
                        .font(AppFont.captionMuted)
                        .foregroundStyle(Color.textMuted)
                } else {
                    HStack(spacing: 20) {
                        // Chart
                        Chart(chartData, id: \.key) { item in
                            SectorMark(
                                angle: .value("Yards", item.value),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .cornerRadius(4)
                            .foregroundStyle(strokeColor(for: item.key))
                        }
                        .frame(width: 100, height: 100)
                        
                        // Legend
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(chartData.prefix(4), id: \.key) { item in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(strokeColor(for: item.key))
                                        .frame(width: 8, height: 8)
                                    
                                    Text(item.key.capitalized)
                                        .font(AppFont.caption)
                                        .foregroundStyle(Color.textPrimary)
                                    
                                    Spacer()
                                    
                                    Text(percentage(item.value, total: totalYards))
                                        .font(AppFont.captionMuted)
                                        .foregroundStyle(Color.textMuted)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 4. Coach's Notes
    private var coachNotesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Coach’s Notes")
                    .font(AppFont.cardTitle)
                    .foregroundStyle(Color.appAccent)
                
                if !practice.aiSummary.isEmpty {
                    Text(practice.aiSummary)
                        .font(AppFont.body)
                        .foregroundStyle(Color.textPrimary)
                }
                
                if let tip = practice.aiTip {
                    Divider().overlay(Color.white.opacity(0.1))
                    HStack(alignment: .top) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(Color.warning)
                            .font(.caption)
                            .padding(.top, 2)
                        Text(tip)
                            .font(AppFont.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
        }
    }
    
    // MARK: - 5. Recovery Suggestions
    private func recoveryCard(_ text: String) -> some View {
        let suggestions = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recovery Suggestions")
                    .font(AppFont.cardTitle)
                    .foregroundStyle(Color.positive)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(suggestions, id: \.self) { line in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color.positive.opacity(0.5))
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            Text(line.replacingOccurrences(of: "• ", with: "").replacingOccurrences(of: "- ", with: ""))
                                .font(AppFont.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 8. Recovery Plan Card
    private var recoveryPlanCard: some View {
        guard let plan = mutablePractice.recoveryPlan, !plan.tasks.isEmpty else {
            return AnyView(GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recovery Plan")
                        .font(AppFont.cardTitle)
                        .foregroundStyle(Color.positive)
                    Text("No recovery plan available for this practice.")
                        .font(AppFont.caption)
                        .foregroundStyle(Color.textMuted)
                }
            })
        }
        
        let filteredTasks = showQuickRecovery ? plan.tasks.filter { $0.includeInQuick } : plan.tasks
        let completedCount = filteredTasks.filter { $0.isCompleted }.count
        let totalCount = filteredTasks.count
        let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
        
        return AnyView(GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header with toggle
                VStack(alignment: .leading, spacing: 8) {
                    // Header row with menu
                    HStack {
                        Text("Recovery Plan")
                            .font(AppFont.cardTitle)
                            .foregroundStyle(Color.positive)
                        
                        Spacer()
                        
                        // Overflow menu
                        Menu {
                            Button {
                                showSaveTemplateSheet = true
                            } label: {
                                Label("Save as template...", systemImage: "square.and.arrow.down")
                            }
                            .disabled(plan.tasks.isEmpty)
                            
                            Button {
                                showApplyTemplateSheet = true
                            } label: {
                                Label("Apply template...", systemImage: "square.and.arrow.up")
                            }
                            .disabled(appData.recoveryTemplates.isEmpty)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title3)
                                .foregroundStyle(Color.appAccent)
                        }
                    }
                    
                    Text("Based on this session's load and focus.")
                        .font(AppFont.caption)
                        .foregroundStyle(Color.textMuted)
                    
                    // Quick / Full toggle
                    HStack(spacing: 16) {
                        Button {
                            showQuickRecovery = true
                        } label: {
                            Text("Quick")
                                .font(AppFont.bodyBold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(showQuickRecovery ? Color.appAccent : Color.clear)
                                .foregroundStyle(showQuickRecovery ? Color.black : Color.textPrimary)
                                .clipShape(Capsule())
                        }
                        
                        Button {
                            showQuickRecovery = false
                        } label: {
                            Text("Full")
                                .font(AppFont.bodyBold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(!showQuickRecovery ? Color.appAccent : Color.clear)
                                .foregroundStyle(!showQuickRecovery ? Color.black : Color.textPrimary)
                                .clipShape(Capsule())
                        }
                    }
                }
                
                // Progress summary
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(showQuickRecovery ? "Quick plan:" : "Full plan:")
                            .font(AppFont.caption)
                            .foregroundStyle(Color.textMuted)
                        Text("\(completedCount) of \(totalCount) complete")
                            .font(AppFont.captionBold)
                            .foregroundStyle(Color.textPrimary)
                    }
                    
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(Color.positive)
                }
                
                Divider().overlay(Color.white.opacity(0.1))
                
                // Task sections by bucket
                ForEach(RecoveryBucket.allCases, id: \.self) { bucket in
                    let tasksInBucket = filteredTasks.filter { $0.bucket == bucket }
                    if !tasksInBucket.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(bucket.displayName)
                                .font(AppFont.captionBold)
                                .foregroundStyle(Color.appAccent)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            
                            ForEach(Array(tasksInBucket.enumerated()), id: \.element.id) { index, task in
                                recoveryTaskRow(task)
                            }
                        }
                    }
                }
            }
        })
    }
    
    private func recoveryTaskRow(_ task: RecoveryTask) -> some View {
        Button {
            toggleTaskCompletion(task)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                // Checkmark circle
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? Color.positive : Color.textMuted)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Task text
                    Text(task.text)
                        .font(AppFont.body)
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Tags
                    HStack(spacing: 8) {
                        TagPill(text: task.bodyRegion.displayName, isSelected: false)
                        TagPill(text: task.kind.displayName, isSelected: false)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func toggleTaskCompletion(_ task: RecoveryTask) {
        guard var plan = mutablePractice.recoveryPlan else { return }
        
        if let index = plan.tasks.firstIndex(where: { $0.id == task.id }) {
            plan.tasks[index].isCompleted.toggle()
            mutablePractice.recoveryPlan = plan
            
            // Persist to AppData
            if let practiceIndex = appData.loggedPractices.firstIndex(where: { $0.id == practice.id }) {
                appData.loggedPractices[practiceIndex].recoveryPlan = plan
            }
            
            Haptics.success()
        }
    }
    
    // MARK: - 7. Effort Mix Card
    private var effortMixCard: some View {
        guard let summary = practice.intensitySummary, summary.totalClassifiedYards > 0 else { return AnyView(EmptyView()) }
        
        let data: [(String, Int, Color)] = [
            ("Easy", summary.easyYards, .blue.opacity(0.5)),
            ("Aerobic", summary.aerobicYards, .green),
            ("Threshold", summary.thresholdYards, .orange),
            ("Race", summary.raceYards, .red),
            ("Sprint", summary.sprintYards, .purple)
        ].filter { $0.1 > 0 }
        
        let total = summary.totalClassifiedYards
        
        return AnyView(GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Effort Mix")
                        .font(AppFont.cardTitle)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Text("\(total) yds")
                        .font(AppFont.captionMuted)
                        .foregroundStyle(Color.textMuted)
                }
                
                HStack(spacing: 20) {
                    // Donut Chart
                    Chart(data, id: \.0) { item in
                        SectorMark(
                            angle: .value("Yards", item.1),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .cornerRadius(4)
                        .foregroundStyle(item.2)
                    }
                    .frame(width: 100, height: 100)
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(data, id: \.0) { item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(item.2)
                                    .frame(width: 8, height: 8)
                                Text(item.0)
                                    .font(AppFont.caption)
                                    .foregroundStyle(Color.textPrimary)
                                Spacer()
                                Text(percentage(item.1, total: total))
                                    .font(AppFont.captionMuted)
                                    .foregroundStyle(Color.textMuted)
                            }
                        }
                    }
                }
                
                // Work vs Recovery Tile
                if summary.workYards > 0 || summary.recoveryYards > 0 {
                    Divider().overlay(Color.white.opacity(0.1))
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Work vs Recovery")
                                .font(AppFont.caption)
                                .foregroundStyle(Color.textMuted)
                            
                            HStack(spacing: 4) {
                                Text("\(percentage(summary.workYards, total: summary.workYards + summary.recoveryYards)) Work")
                                    .foregroundStyle(Color.orange)
                                Text("·")
                                    .foregroundStyle(Color.textMuted)
                                Text("\(percentage(summary.recoveryYards, total: summary.workYards + summary.recoveryYards)) Recovery")
                                    .foregroundStyle(Color.blue)
                            }
                            .font(AppFont.bodyBold)
                        }
                        
                        Spacer()
                        
                        if let insights = practice.insights, let strain = insights.strainCategory {
                            Text(strain)
                                .font(AppFont.smallTag)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(strainColor(strain).opacity(0.2))
                                .foregroundStyle(strainColor(strain))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        })
    }
    
    // MARK: - 8. Highlights Card
    private var highlightsCard: some View {
        guard let insights = practice.insights, !insights.highlightBullets.isEmpty else { return AnyView(EmptyView()) }
        
        return AnyView(GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Highlights")
                        .font(AppFont.cardTitle)
                        .foregroundStyle(Color.appAccent)
                    Spacer()
                    if let score = insights.difficultyScore {
                        Text("Difficulty: \(score)/10")
                            .font(AppFont.captionBold)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                
                if !insights.focusTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(insights.focusTags, id: \.self) { tag in
                                TagPill(text: tag, isSelected: true)
                            }
                        }
                    }
                    .padding(.bottom, 4)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(insights.highlightBullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundStyle(Color.appAccent)
                                .padding(.top, 2)
                            Text(bullet)
                                .font(AppFont.body)
                                .foregroundStyle(Color.textPrimary)
                        }
                    }
                }
            }
        })
    }
    
    private func strainColor(_ strain: String) -> Color {
        switch strain.lowercased() {
        case "low": return .green
        case "medium": return .yellow
        case "high": return .red
        default: return .gray
        }
    }
    
    // MARK: - 2. Practice Sheet Card (Large Preview)
    private var pdfPreviewCard: some View {
        let pdfURL = appData.pdfURL(for: practice.id)
        let pdfExists = FileManager.default.fileExists(atPath: pdfURL.path)
        
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Practice Sheet", systemImage: "doc.text.fill")
                        .font(AppFont.cardTitle)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    
                    if pdfExists {
                        Button {
                            showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.caption)
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .foregroundStyle(Color.textPrimary)
                                .clipShape(Circle())
                        }
                    }
                }
                
                if pdfExists {
                    // Large Readable Preview
                    Button {
                        selectedPDFURL = pdfURL
                    } label: {
                        ZStack {
                            if let thumb = pdfThumbnail {
                                Image(uiImage: thumb)
                                    .resizable()
                                    .scaledToFill() // Fill width
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 300, alignment: .top) // Show top portion or scaled fit
                                    .clipped()
                                    .overlay(
                                        LinearGradient(colors: [.black.opacity(0.0), .black.opacity(0.2)], startPoint: .center, endPoint: .bottom)
                                    )
                            } else {
                                Rectangle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 300)
                                    .overlay(ProgressView())
                                    .onAppear { loadThumbnail(url: pdfURL) }
                            }
                            
                            // "Tap to view" overlay
                            VStack {
                                Spacer()
                                HStack {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    Text("Tap to view full screen")
                                }
                                .font(AppFont.captionBold)
                                .foregroundStyle(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .padding(.bottom, 12)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                } else {
                    // No PDF State - Auto-generate or manual trigger
                    VStack(alignment: .center, spacing: 12) {
                        Text("Practice sheet PDF not found.")
                            .font(AppFont.caption)
                            .foregroundStyle(Color.textMuted)
                        
                        Button {
                            generatePDF()
                        } label: {
                            HStack {
                                if isGeneratingPDF {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                }
                                Text(isGeneratingPDF ? "Generating PDF..." : "Generate PDF Now")
                            }
                            .font(AppFont.bodyBold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.1))
                            .foregroundStyle(Color.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(isGeneratingPDF)
                    }
                    .padding(.vertical, 20)
                    .onAppear {
                        // Attempt auto-generation if missing (e.g. old practice)
                        if !isGeneratingPDF {
                            generatePDF()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - PDF Logic
    
    private func loadThumbnail(url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let doc = PDFDocument(url: url), let page = doc.page(at: 0) else { return }
            // Generate a high-res thumbnail for the large preview
            let width: CGFloat = 600 // High res width
            let pageRect = page.bounds(for: .mediaBox)
            let scale = width / pageRect.width
            let height = pageRect.height * scale
            let thumb = page.thumbnail(of: CGSize(width: width, height: height), for: .mediaBox)
            
            DispatchQueue.main.async {
                self.pdfThumbnail = thumb
            }
        }
    }
    
    private func generatePDF() {
        isGeneratingPDF = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Use formatted text or fallback to raw text
            let textToUse = !practice.formattedText.isEmpty ? practice.formattedText : "No text available"
            
            if let url = PracticeSheetPDFGenerator.generateSheetPDF(from: textToUse, practiceID: practice.id) {
                // Success
                DispatchQueue.main.async {
                    self.isGeneratingPDF = false
                    // Trigger thumbnail load
                    self.loadThumbnail(url: url)
                }
            } else {
                // Failure
                DispatchQueue.main.async {
                    self.isGeneratingPDF = false
                    // Could show error alert here
                }
            }
        }
    }
    
    // MARK: - Helpers
    private var formattedPracticeTitle: String {
        if let date = ISO8601DateFormatter().date(from: practice.date) {
            return date.formatted(.dateTime.weekday(.wide).month().day())
        }
        return "Swim Practice"
    }
    
    private var dateAndTimeText: String {
        var text = ""
        if let date = ISO8601DateFormatter().date(from: practice.date) {
            text += date.formatted(date: .abbreviated, time: .omitted)
        }
        if let time = practice.timeOfDay {
            text += " · \(time)"
        }
        return text
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
    
    private func percentage(_ value: Int, total: Int? = nil) -> String {
        let t = total ?? practice.distanceYards
        guard t > 0 else { return "0%" }
        let p = Int((Double(value) / Double(t)) * 100)
        return "\(p)%"
    }
    
    private func sectionColor(for section: String) -> Color {
        switch section.lowercased() {
        case "warmup": return Color.blue.opacity(0.6)
        case "preset": return Color.orange.opacity(0.6)
        case "main set": return Color.appAccent
        case "post-set": return Color.purple.opacity(0.6)
        case "cooldown": return Color.green.opacity(0.6)
        default: return Color.gray.opacity(0.4)
        }
    }
    
    private func strokeColor(for stroke: String) -> Color {
        let s = stroke.lowercased()
        if s.contains("free") { return Color.appAccent }
        if s.contains("back") { return Color.blue }
        if s.contains("breast") { return Color.green }
        if s.contains("fly") || s.contains("butter") { return Color.purple }
        if s.contains("im") { return Color.indigo }
        if s.contains("kick") { return Color.yellow }
        if s.contains("drill") { return Color.gray }
        return Color.white.opacity(0.3)
    }
    
    private func updatePractice(newDate: Date, newDuration: Int, newTimeOfDay: String) {
        // ... existing update logic ...
        guard let idx = appData.loggedPractices.firstIndex(where: { $0.id == practice.id }) else { return }
        var updated = appData.loggedPractices[idx]
        updated = AnalyzedPractice(
            id: updated.id,
            date: ISO8601DateFormatter().string(from: newDate),
            formattedText: updated.formattedText,
            aiSummary: updated.aiSummary,
            distanceYards: updated.distanceYards,
            durationMinutes: newDuration,
            sectionYards: updated.sectionYards,
            strokePercentages: updated.strokePercentages,
            aiTip: updated.aiTip,
            timeOfDay: newTimeOfDay,
            practiceTag: updated.practiceTag,
            recoverySuggestions: updated.recoverySuggestions,
            title: updated.title,
            intensitySummary: updated.intensitySummary,
            insights: updated.insights,
            recoveryPlan: updated.recoveryPlan
        )
        appData.updatePractice(updated)
    }
    
    // MARK: - Recovery Template Application
    private func applyTemplate(_ template: RecoveryTemplate) {
        // Create new tasks from template with isCompleted reset
        let newTasks = template.tasks.map { task in
            RecoveryTask(
                id: UUID(), // New UUID for this practice
                text: task.text,
                bucket: task.bucket,
                bodyRegion: task.bodyRegion,
                kind: task.kind,
                includeInQuick: task.includeInQuick,
                isCompleted: false
            )
        }
        
        // Update mutable practice's recovery plan
        mutablePractice.recoveryPlan = RecoveryPlan(tasks: newTasks)
        
        // Persist to AppData
        if let practiceIndex = appData.loggedPractices.firstIndex(where: { $0.id == practice.id }) {
            appData.loggedPractices[practiceIndex].recoveryPlan = RecoveryPlan(tasks: newTasks)
        }
        
        Haptics.success()
    }
}

// Reuse EditPracticeSheet from before (or keep it if it was inline)
// Assuming EditPracticeSheet is defined elsewhere or I should include it here.
// I'll include it here to be safe, as it was in the previous file.

struct EditPracticeSheet: View {
    let practice: AnalyzedPractice
    @Binding var date: Date
    @Binding var duration: Int
    @Binding var timeOfDay: String
    var onSave: (Date, Int, String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Practice Info") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Stepper("Duration: \(duration) min", value: $duration, in: 0...300, step: 15)
                    Picker("Time of Day", selection: $timeOfDay) {
                        Text("Morning (AM)").tag("AM")
                        Text("Afternoon (PM)").tag("PM")
                        Text("Evening").tag("Evening")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Edit Practice")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(date, duration, timeOfDay)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
