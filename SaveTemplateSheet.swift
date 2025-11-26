import SwiftUI

struct SaveTemplateSheet: View {
    @EnvironmentObject var appData: AppData
    @Environment(\.dismiss) var dismiss
    
    let sourcePractice: AnalyzedPractice
    let recoveryPlan: RecoveryPlan
    
    @State private var templateName: String
    @State private var templateDescription: String = ""
    
    init(sourcePractice: AnalyzedPractice, recoveryPlan: RecoveryPlan) {
        self.sourcePractice = sourcePractice
        self.recoveryPlan = recoveryPlan
        
        // Generate smart default name from practice context
        var defaultName = "Recovery Plan"
        if let tag = sourcePractice.practiceTag, !tag.isEmpty {
            defaultName = "Post-\(tag)"
        } else if let strain = sourcePractice.insights?.strainCategory {
            defaultName = "\(strain) Day Recovery"
        }
        _templateName = State(initialValue: defaultName)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Form
                        VStack(alignment: .leading, spacing: 16) {
                            // Name field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Template Name")
                                    .font(AppFont.captionBold)
                                    .foregroundStyle(Color.textMuted)
                                
                                TextField("", text: $templateName)
                                    .font(AppFont.body)
                                    .foregroundStyle(Color.textPrimary)
                                    .textInputAutocapitalization(.words)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.05))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    )
                            }
                            
                            // Description field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description (Optional)")
                                    .font(AppFont.captionBold)
                                    .foregroundStyle(Color.textMuted)
                                
                                TextField("", text: $templateDescription, axis: .vertical)
                                    .font(AppFont.body)
                                    .foregroundStyle(Color.textPrimary)
                                    .lineLimit(3...5)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.05))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Preview
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Preview")
                                    .font(AppFont.cardTitle)
                                    .foregroundStyle(Color.textPrimary)
                                
                                Text("\(recoveryPlan.tasks.count) tasks")
                                    .font(AppFont.caption)
                                    .foregroundStyle(Color.textMuted)
                                
                                let quickCount = recoveryPlan.tasks.filter { $0.includeInQuick }.count
                                if quickCount > 0 {
                                    Text("\(quickCount) marked for Quick routine")
                                        .font(AppFont.caption)
                                        .foregroundStyle(Color.positive)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Save Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .disabled(templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveTemplate() {
        let trimmedName = templateName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = templateDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Create tasks with isCompleted reset to false
        let cleanedTasks = recoveryPlan.tasks.map { task in
            RecoveryTask(
                id: UUID(), // New ID for template
                text: task.text,
                bucket: task.bucket,
                bodyRegion: task.bodyRegion,
                kind: task.kind,
                includeInQuick: task.includeInQuick,
                isCompleted: false
            )
        }
        
        let template = RecoveryTemplate(
            name: trimmedName,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription,
            tasks: cleanedTasks
        )
        
        appData.addRecoveryTemplate(template)
        dismiss()
    }
}
