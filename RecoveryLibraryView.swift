import SwiftUI

struct RecoveryLibraryView: View {
    @EnvironmentObject var appData: AppData
    @Environment(\.dismiss) var dismiss
    
    // Picker mode for template selection
    let isPickerMode: Bool
    let onSelect: ((RecoveryTemplate) -> Void)?
    
    init(isPickerMode: Bool = false, onSelect: ((RecoveryTemplate) -> Void)? = nil) {
        self.isPickerMode = isPickerMode
        self.onSelect = onSelect
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        if appData.recoveryTemplates.isEmpty {
                            emptyState
                        } else {
                            ForEach(appData.recoveryTemplates.sorted(by: { $0.createdAt > $1.createdAt })) { template in
                                if isPickerMode {
                                    // Picker mode: tappable row
                                    Button {
                                        onSelect?(template)
                                        dismiss()
                                    } label: {
                                        templateRow(template)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    // Browse mode: navigation link
                                    NavigationLink {
                                        RecoveryTemplateDetailView(template: template)
                                            .environmentObject(appData)
                                    } label: {
                                        templateRow(template)
                                    }
                                    .buttonStyle(.plain)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            appData.deleteRecoveryTemplate(template)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(isPickerMode ? "Choose Template" : "Recovery Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isPickerMode {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private func templateRow(_ template: RecoveryTemplate) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                // Template name
                Text(template.name)
                    .font(AppFont.cardTitle)
                    .foregroundStyle(Color.textPrimary)
                
                // Description
                if let description = template.description, !description.isEmpty {
                    Text(description)
                        .font(AppFont.caption)
                        .foregroundStyle(Color.textMuted)
                        .lineLimit(2)
                }
                
                Divider().overlay(Color.white.opacity(0.1))
                
                // Metadata row
                HStack(spacing: 16) {
                    // Task count
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.caption)
                            .foregroundStyle(Color.positive)
                        Text("\(template.taskCount) tasks")
                            .font(AppFont.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                    
                    // Quick routine indicator
                    if template.isQuickRoutine {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.caption)
                                .foregroundStyle(Color.appAccent)
                            Text("Quick")
                                .font(AppFont.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    
                    // Estimated time
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundStyle(Color.textMuted)
                        Text("~\(template.estimatedMinutes)m")
                            .font(AppFont.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(Color.textMuted)
                .padding(.top, 60)
            
            Text("No Templates Yet")
                .font(AppFont.cardTitle)
                .foregroundStyle(Color.textPrimary)
            
            Text("Save a recovery plan from Practice Detail to create your first template.")
                .font(AppFont.caption)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}
