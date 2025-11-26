import SwiftUI

struct EditBlockView: View {
    @Binding var block: PracticeSet
    @Environment(\.dismiss) var dismiss
    
    // State for pattern picker
    @State private var showingPatternPicker: PatternCategory?
    @State private var editingLineId: UUID?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Block Summary (Title & Rounds)
                        blockSummaryCard
                        
                        // 2. Lines List
                        linesListCard
                        
                        // 3. Preview
                        previewCard
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $showingPatternPicker) { category in
                if let lineId = editingLineId,
                   let index = block.lines.firstIndex(where: { $0.id == lineId }) {
                    PatternPickerView(category: category, patterns: $block.lines[index].patterns) {
                        // Dismiss action
                    }
                    .presentationDetents([.medium, .large])
                }
            }
        }
    }
    
    // MARK: - 1. Block Summary
    private var blockSummaryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // Title Input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Block Title (Optional)")
                        .font(AppFont.caption.weight(.semibold))
                        .foregroundStyle(Color.textSecondary)
                    
                    TextField("e.g. Warmup Set", text: Binding(
                        get: { block.title ?? "" },
                        set: { block.title = $0.isEmpty ? nil : $0 }
                    ))
                    .font(AppFont.cardTitle)
                    .foregroundStyle(Color.textPrimary)
                    .padding(12)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                }
                
                Divider().overlay(Color.white.opacity(0.1))
                
                // Rounds Stepper
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rounds")
                            .font(AppFont.bodyBold)
                            .foregroundStyle(Color.textPrimary)
                        if block.repeatCount > 1 {
                            Text("Total: \(block.totalYards) yds")
                                .font(AppFont.caption)
                                .foregroundStyle(Color.appAccent)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 0) {
                        Button {
                            if block.repeatCount > 1 { block.repeatCount -= 1 }
                        } label: {
                            Image(systemName: "minus")
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.1))
                        }
                        
                        Text("\(block.repeatCount)")
                            .font(AppFont.title3.weight(.bold))
                            .frame(width: 50)
                            .foregroundStyle(Color.textPrimary)
                        
                        Button {
                            block.repeatCount += 1
                        } label: {
                            Image(systemName: "plus")
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.1))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - 2. Lines List
    private var linesListCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Swim Lines")
                        .font(AppFont.cardTitle)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Button {
                        addLine()
                    } label: {
                        Label("Add Line", systemImage: "plus")
                            .font(AppFont.caption.weight(.bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.appAccent, in: Capsule())
                            .foregroundStyle(Color.black)
                    }
                }
                
                if block.lines.isEmpty {
                    Text("No lines added yet.")
                        .font(AppFont.body)
                        .foregroundStyle(Color.textMuted)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach($block.lines) { $line in
                        BlockLineEditor(
                            line: $line,
                            onDelete: { deleteLine(line.id) },
                            onPattern: { cat in
                                editingLineId = line.id
                                showingPatternPicker = cat
                            }
                        )
                        
                        if line.id != block.lines.last?.id {
                            Divider().overlay(Color.white.opacity(0.1))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 3. Preview
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PREVIEW")
                .font(AppFont.caption.weight(.bold))
                .foregroundStyle(Color.textMuted)
                .padding(.leading, 4)
            
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    if let title = block.title {
                        Text(title)
                            .font(AppFont.bodyBold)
                            .foregroundStyle(Color.textPrimary)
                    }
                    
                    if block.repeatCount > 1 {
                        Text("\(block.repeatCount)x Rounds:")
                            .font(AppFont.body)
                            .foregroundStyle(Color.appAccent)
                    }
                    
                    ForEach(block.lines) { line in
                        Text(formatLinePreview(line))
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(Color.textSecondary)
                    }
                    
                    Divider().overlay(Color.white.opacity(0.1))
                    
                    HStack {
                        Spacer()
                        Text("Block Total: \(block.totalYards) yds")
                            .font(AppFont.bodyBold)
                            .foregroundStyle(Color.appAccent)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    private func addLine() {
        let newLine = PracticeLine(
            id: UUID(),
            reps: 4,
            distance: 50,
            stroke: .freestyle,
            interval: nil,
            intervalType: .interval,
            text: "",
            yardageOverride: nil
        )
        block.lines.append(newLine)
    }
    
    private func deleteLine(_ id: UUID) {
        block.lines.removeAll { $0.id == id }
    }
    
    private func formatLinePreview(_ line: PracticeLine) -> String {
        var parts: [String] = []
        
        // 1. Reps x Dist
        if let r = line.reps, let d = line.distance {
            parts.append("\(r)x\(d)")
        } else if let d = line.distance {
            parts.append("\(d)")
        }
        
        // 2. Stroke
        if let sPattern = line.patterns.stroke {
            parts.append(sPattern.label)
        } else if let s = line.stroke {
            parts.append(s.displayName)
        }
        
        // 3. Interval
        if let interval = line.interval {
            if line.intervalType == .interval {
                parts.append("@ \(interval)")
            } else {
                parts.append("Rest \(interval)")
            }
        }
        
        // 4. Modifiers
        var mods: [String] = []
        if let p = line.patterns.pace { mods.append(p.label) }
        if !line.patterns.focus.isEmpty { mods.append(line.patterns.focus.map(\.label).joined(separator: "/")) }
        if !mods.isEmpty {
            parts.append("(\(mods.joined(separator: ", ")))")
        }
        
        // 5. Note
        if !line.text.isEmpty {
            parts.append("– \(line.text)")
        }
        
        return parts.joined(separator: " ")
    }
}

// MARK: - Line Editor Row
struct BlockLineEditor: View {
    @Binding var line: PracticeLine
    var onDelete: () -> Void
    var onPattern: (PatternCategory) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Row 1: Reps, Dist, Stroke
            HStack(spacing: 8) {
                // Reps
                TextField("4", value: $line.reps, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(Color.textPrimary)
                
                Text("×")
                    .foregroundStyle(Color.textMuted)
                
                // Dist
                TextField("50", value: $line.distance, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 50, height: 44)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(Color.textPrimary)
                
                // Stroke Picker
                Menu {
                    ForEach(StrokeType.allCases) { s in
                        Button(s.displayName) {
                            line.stroke = s
                            line.patterns.stroke = nil
                        }
                    }
                } label: {
                    HStack {
                        Text(line.patterns.stroke?.label ?? line.stroke?.displayName ?? "Free")
                            .font(AppFont.body)
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(Color.textMuted)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            
            // Row 2: Interval & Modifiers
            HStack(spacing: 8) {
                // Interval
                HStack(spacing: 0) {
                    Menu {
                        Button("@ Interval") { line.intervalType = .interval }
                        Button("Rest") { line.intervalType = .rest }
                    } label: {
                        Text(line.intervalType == .interval ? "@" : "R")
                            .font(AppFont.bodyBold)
                            .foregroundStyle(line.intervalType == .interval ? Color.appAccent : Color.warning)
                            .frame(width: 36, height: 44)
                            .background(Color.white.opacity(0.1))
                    }
                    
                    Divider().overlay(Color.white.opacity(0.2))
                    
                    TextField(":45", text: Binding(
                        get: { line.interval ?? "" },
                        set: { line.interval = $0.isEmpty ? nil : $0 }
                    ))
                    .multilineTextAlignment(.center)
                    .frame(height: 44)
                    .foregroundStyle(Color.textPrimary)
                }
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Modifiers (Pace, Focus, Note)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Pace
                        Button { onPattern(.pace) } label: {
                            modifierPill(
                                label: line.patterns.pace?.label ?? "Pace",
                                isActive: line.patterns.pace != nil,
                                icon: "speedometer"
                            )
                        }
                        
                        // Focus
                        Button { onPattern(.focus) } label: {
                            modifierPill(
                                label: line.patterns.focus.isEmpty ? "Focus" : "\(line.patterns.focus.count)",
                                isActive: !line.patterns.focus.isEmpty,
                                icon: "eye"
                            )
                        }
                        
                        // Note (Text)
                        Button {
                            // No-op, just shows field below if needed?
                            // Or maybe we just have a text field?
                            // Let's just add a text field below if they type in it.
                        } label: {
                            // Just a visual indicator that notes are available
                            // Actually, let's put the note field in the row if it has content, or a button to add it.
                            // For simplicity, I'll just add a text field below.
                        }
                    }
                }
            }
            
            // Row 3: Note Input
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundStyle(Color.textMuted)
                TextField("Add note...", text: $line.text)
                    .font(AppFont.body)
                    .foregroundStyle(Color.textPrimary)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(Color.danger)
                        .padding(8)
                        .background(Color.danger.opacity(0.1), in: Circle())
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(12)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func modifierPill(label: String, isActive: Bool, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(label)
        }
        .font(AppFont.caption.weight(.medium))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isActive ? Color.appAccent.opacity(0.2) : Color.white.opacity(0.1))
        .foregroundStyle(isActive ? Color.appAccent : Color.textSecondary)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(isActive ? Color.appAccent.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}

// Reuse PatternPickerView from EditSetView (assuming it's compatible or I need to copy it)
// I will copy it here to be safe and self-contained.

struct PatternPickerView: View {
    var category: PatternCategory
    @Binding var patterns: SetPatterns
    var onDismiss: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                List {
                    switch category {
                    case .pace:
                        Section("Pace & Effort") {
                            ForEach(PacePattern.allCases) { pattern in
                                patternRow(label: pattern.label, desc: pattern.defaultDescription, isSelected: patterns.pace == pattern) {
                                    patterns.pace = (patterns.pace == pattern) ? nil : pattern
                                }
                            }
                        }
                    case .stroke:
                        Section("Stroke & Style") {
                            ForEach(StrokePattern.allCases) { pattern in
                                patternRow(label: pattern.label, desc: pattern.defaultDescription, isSelected: patterns.stroke == pattern) {
                                    patterns.stroke = (patterns.stroke == pattern) ? nil : pattern
                                }
                            }
                        }
                    case .focus:
                        Section("Focus & Technique") {
                            ForEach(FocusTag.allCases) { tag in
                                patternRow(label: tag.label, desc: tag.defaultDescription, isSelected: patterns.focus.contains(tag)) {
                                    if let idx = patterns.focus.firstIndex(of: tag) {
                                        patterns.focus.remove(at: idx)
                                    } else {
                                        patterns.focus.append(tag)
                                    }
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(category.rawValue.capitalized)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDismiss()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func patternRow(label: String, desc: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(AppFont.body)
                        .foregroundStyle(Color.textPrimary)
                    Text(desc)
                        .font(AppFont.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.appAccent)
                }
            }
        }
        .listRowBackground(Color.white.opacity(0.05))
    }
}
