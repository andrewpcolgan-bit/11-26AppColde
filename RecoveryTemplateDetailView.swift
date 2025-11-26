import SwiftUI

struct RecoveryTemplateDetailView: View {
    @EnvironmentObject var appData: AppData
    let template: RecoveryTemplate
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(template.name)
                            .font(AppFont.pageTitle)
                            .foregroundStyle(Color.textPrimary)
                        
                        if let description = template.description, !description.isEmpty {
                            Text(description)
                                .font(AppFont.body)
                                .foregroundStyle(Color.textSecondary)
                        }
                        
                        // Metadata
                        HStack(spacing: 20) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle")
                                    .font(.caption)
                                Text("\(template.taskCount) tasks")
                                    .font(AppFont.caption)
                            }
                            .foregroundStyle(Color.positive)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                Text("~\(template.estimatedMinutes) min")
                                    .font(AppFont.caption)
                            }
                            .foregroundStyle(Color.textMuted)
                            
                            if template.isQuickRoutine {
                                HStack(spacing: 6) {
                                    Image(systemName: "bolt.fill")
                                        .font(.caption)
                                    Text("Quick")
                                        .font(AppFont.caption)
                                }
                                .foregroundStyle(Color.appAccent)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Task sections by bucket
                    ForEach(RecoveryBucket.allCases, id: \.self) { bucket in
                        let tasksInBucket = template.tasks.filter { $0.bucket == bucket }
                        if !tasksInBucket.isEmpty {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text(bucket.displayName)
                                        .font(AppFont.cardTitle)
                                        .foregroundStyle(Color.appAccent)
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                    
                                    ForEach(tasksInBucket) { task in
                                        templateTaskRow(task)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Template")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func templateTaskRow(_ task: RecoveryTask) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon (read-only)
            Image(systemName: "circle")
                .font(.title3)
                .foregroundStyle(Color.textMuted)
            
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
                    if task.includeInQuick {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.caption2)
                            Text("Quick")
                                .font(AppFont.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.appAccent.opacity(0.2))
                        .foregroundStyle(Color.appAccent)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }
}
