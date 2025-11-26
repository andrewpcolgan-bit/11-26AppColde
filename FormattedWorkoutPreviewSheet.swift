import SwiftUI

struct FormattedWorkoutPreviewSheet: View {
    let preview: FormattedWorkoutPreview
    let onApply: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header stats
                    headerCard
                    
                    // Issues (if any)
                    if !preview.response.issues.isEmpty {
                        issuesCard
                    }
                    
                    // Sections
                    ForEach(preview.response.sections) { section in
                        sectionCard(section)
                    }
                }
                .padding()
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("AI Formatted Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyFormatting()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Yardage")
                            .font(AppFont.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                        
                        Text("\(preview.totalYards)")
                            .font(AppFont.pageTitle)
                            .foregroundStyle(AppColor.accent)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Total Sets")
                            .font(AppFont.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                        
                        Text("\(preview.totalSets)")
                            .font(AppFont.title3.weight(.bold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sections")
                            .font(AppFont.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                        
                        Text("\(preview.response.sections.count)")
                            .font(AppFont.body.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    if !preview.response.issues.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                            Text("\(preview.response.issues.count) issue\(preview.response.issues.count == 1 ? "" : "s")")
                                .font(AppFont.caption.weight(.semibold))
                        }
                        .foregroundStyle(.yellow)
                    }
                }
            }
        }
    }
    
    // MARK: - Issues Card
    
    private var issuesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("Parsing Issues")
                        .font(AppFont.cardTitle)
                        .foregroundStyle(.white)
                    Spacer()
                }
                
                Divider().background(AppColor.border)
                
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(preview.response.issues) { issue in
                        issueRow(issue)
                    }
                }
            }
        }
    }
    
    private func issueRow(_ issue: FormatIssueDTO) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text("Line \(issue.lineNumber)")
                    .font(AppFont.caption.weight(.semibold))
                    .foregroundStyle(.yellow)
                
                Spacer()
                
                Text(issue.reason)
                    .font(AppFont.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Text(issue.lineText)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
    
    // MARK: - Section Card
    
    private func sectionCard(_ section: FormattedSectionDTO) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(section.title)
                        .font(AppFont.cardTitle)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    let sectionYards = section.blocks.reduce(0) { sum, block in
                        let yards = (block.distance ?? 0) * block.reps
                        return sum + yards
                    }
                    
                    Text("\(sectionYards) yds")
                        .font(AppFont.caption.weight(.semibold))
                        .foregroundStyle(AppColor.accent)
                }
                
                if !section.blocks.isEmpty {
                    Divider().background(AppColor.border)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(section.blocks.indices, id: \.self) { index in
                            blockRow(section.blocks[index])
                            
                            if index < section.blocks.count - 1 {
                                Divider().background(AppColor.border.opacity(0.3))
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func blockRow(_ block: FormattedBlockDTO) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(block.displayText)
                .font(AppFont.body)
                .foregroundStyle(.white.opacity(0.9))
            
            if !block.notes.isEmpty {
                Text(block.notes)
                    .font(AppFont.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            if !block.equipment.isEmpty {
                HStack(spacing: 6) {
                    ForEach(block.equipment, id: \.self) { item in
                        Text(item)
                            .font(AppFont.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppColor.accent.opacity(0.2))
                            .foregroundStyle(AppColor.accent)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Actions
    
    private func applyFormatting() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        onApply()
    }
}
