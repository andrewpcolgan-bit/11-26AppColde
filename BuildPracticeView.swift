import SwiftUI

struct BuildPracticeView: View {
    @EnvironmentObject var appData: AppData
    @Environment(\.dismiss) var dismiss

    enum Mode: Hashable {
        case create
        case edit(BuiltPracticeTemplate)
    }
    
    enum BuilderMode: String, CaseIterable, Identifiable {
        case blocks = "Blocks"
        case text = "Text"
        var id: String { rawValue }
    }

    let mode: Mode

    @State private var draft: BuiltPracticeTemplate
    @State private var builderMode: BuilderMode = .blocks

    @State private var showSetComposer = false
    @State private var composerContext: SetComposerContext?
    @State private var notesExpanded = false
    
    @State private var showToast = false
    @State private var toastMessage = ""
    
    struct SetComposerContext {
        let sectionIndex: Int
        let setIndex: Int? // nil for new, index for edit
    }

    init(mode: Mode) {
        self.mode = mode

        switch mode {
        case .create:
            let newTemplate = BuiltPracticeTemplate(
                id: UUID(),
                title: "",
                notes: nil,
                poolInfo: "25 Yards",
                tag: nil,
                sections: [
                    PracticeSection(id: UUID(), label: "Warmup",                sets: []),
                    PracticeSection(id: UUID(), label: "Pre-Set",               sets: []),
                    PracticeSection(id: UUID(), label: "Main Set",              sets: []),
                    PracticeSection(id: UUID(), label: "Post-Set / Technique",  sets: []),
                    PracticeSection(id: UUID(), label: "Cooldown",              sets: [])
                ],
                createdAt: Date(),
                lastEditedAt: Date()
            )
            _draft = State(initialValue: newTemplate)

        case .edit(let template):
            _draft = State(initialValue: template)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Picker("Builder Mode", selection: $builderMode) {
                ForEach(BuilderMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .background(AppColor.background)
            
            switch builderMode {
            case .blocks:
                blocksBuilderView
            case .text:
                TextPracticeBuilderView(practice: $draft, builderMode: $builderMode)
            }
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle(mode == .create ? "Build Practice" : "Edit Practice")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(draft.totalYards == 0)
            }
        }
        .sheet(isPresented: $showSetComposer) {
            if let context = composerContext {
                NavigationStack {
                    SetComposerView(
                        sectionLabel: draft.sections[context.sectionIndex].label,
                        existingSet: context.setIndex.map { draft.sections[context.sectionIndex].sets[$0] },
                        onSave: { newSet in
                            if let setIndex = context.setIndex {
                                draft.sections[context.sectionIndex].sets[setIndex] = newSet
                            } else {
                                draft.sections[context.sectionIndex].sets.append(newSet)
                            }
                            draft.lastEditedAt = Date()
                        },
                        onDelete: {
                            if let setIndex = context.setIndex {
                                draft.sections[context.sectionIndex].sets.remove(at: setIndex)
                                draft.lastEditedAt = Date()
                            }
                        }
                    )
                    .navigationTitle(context.setIndex == nil ? "Add to \(draft.sections[context.sectionIndex].label)" : "Edit Set")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if builderMode == .blocks {
                totalYardageBar
            }
        }
        .overlay(alignment: .bottom) {
            if showToast {
                Text(toastMessage)
                    .font(AppFont.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.8))
                    .clipShape(Capsule())
                    .padding(.bottom, 60)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(100)
            }
        }
    }
    
    @ViewBuilder
    private var blocksBuilderView: some View {
        ScrollView {
            content
        }
    }
    
    private var content: some View {
        VStack(spacing: 16) {
            headerCard

            if draft.totalYards > 0 {
                strokeMixSummary
            }

            sectionsList
        }
        .padding(AppLayout.padding)
    }

    // MARK: - Header card

    // Helper bindings to keep the view simpler for the compiler
    private var notesBinding: Binding<String> {
        Binding(
            get: { draft.notes ?? "" },
            set: { draft.notes = $0.isEmpty ? nil : $0 }
        )
    }

    private var poolInfoBinding: Binding<String> {
        Binding(
            get: { draft.poolInfo ?? "" },
            set: { draft.poolInfo = $0.isEmpty ? nil : $0 }
        )
    }




    private var headerCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // Section Label
                Text("PRACTICE INFO")
                    .font(AppFont.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(1) // Small caps style spacing
                
                // Row 1: Title and Total Yards Badge
                HStack(alignment: .center, spacing: 12) {
                    TextField("Practice Title", text: $draft.title)
                        .font(AppFont.title3.weight(.semibold)) // Larger font
                        .foregroundStyle(.white)
                        .placeholder(when: draft.title.isEmpty) {
                            Text("Practice Title")
                                .foregroundColor(.white.opacity(0.3))
                                .font(AppFont.title3.weight(.semibold))
                        }
                        .submitLabel(.done)
                    
                    Spacer()
                    
                    // Total Yards Badge (Pill)
                    // Wrapped in Button for future interactivity as requested
                    Button {
                        // Placeholder action
                    } label: {
                        HStack(spacing: 2) {
                            Text("\(draft.totalYards)")
                                .font(AppFont.body.weight(.bold))
                                .foregroundStyle(AppColor.accent)
                            Text("yds")
                                .font(AppFont.caption.weight(.medium))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppColor.accent.opacity(0.1), in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(AppColor.accent.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Row 2: Sub-info (Pool + Tag)
                HStack(spacing: 16) {
                    // Pool Chips
                    HStack(spacing: 4) {
                        ForEach(["25y", "25m", "50m"], id: \.self) { pool in
                            Button {
                                draft.poolInfo = poolDisplayToFull(pool)
                            } label: {
                                Text(pool)
                                    .font(AppFont.caption.weight(poolMatches(pool) ? .bold : .medium))
                                    .foregroundStyle(poolMatches(pool) ? Color.black : Color.white.opacity(0.7))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(poolMatches(pool) ? Color.appAccent : Color.white.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Tag Chip (Menu)
                    // Tag Chip (Menu)
                    Menu {
                        ForEach(PracticeTag.allCases) { tag in
                            Button(tag.rawValue) { draft.tag = tag }
                        }
                        Button("Clear") { draft.tag = nil }
                    } label: {
                        HStack(spacing: 4) {
                            Text(draft.tag?.rawValue ?? "Select Tag")
                                .font(AppFont.caption.weight(draft.tag != nil ? .bold : .medium))
                                .foregroundStyle(draft.tag != nil ? Color.black : Color.white.opacity(0.7))
                            
                            if draft.tag == nil {
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(draft.tag != nil ? Color.appAccent : Color.white.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }

                Divider().background(AppColor.border)

                // Row 3: Notes (Collapsible)
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        withAnimation(.snappy) {
                            notesExpanded.toggle()
                        }
                    } label: {
                        HStack {
                            Text("Notes")
                                .font(AppFont.body.weight(.medium))
                                .foregroundStyle(.white.opacity(0.8))
                            Spacer()
                            Image(systemName: notesExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .contentShape(Rectangle()) // Make full width tappable
                    }
                    .buttonStyle(.plain)
                    
                    if notesExpanded {
                        TextField("e.g. Team Practice, IM Focus", text: notesBinding)
                            .font(AppFont.body)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                            .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
                    } else if let notes = draft.notes, !notes.isEmpty {
                        Text(notes)
                            .font(AppFont.caption)
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }
            }
            .padding(.vertical, 4) // Extra internal padding for the card content
        }
    }
    
    private func poolMatches(_ display: String) -> Bool {
        guard let current = draft.poolInfo else { return false }
        return current.contains(display.replacingOccurrences(of: "y", with: " Yards").replacingOccurrences(of: "m", with: " Meters"))
    }
    
    private func poolDisplayToFull(_ display: String) -> String {
        switch display {
        case "25y": return "25 Yards"
        case "25m": return "25 Meters"
        case "50m": return "50 Meters"
        default: return display
        }
    }

    // MARK: - Stroke mix summary

    private var strokeMixSummary: some View {
        let mix = draft.strokeYards()
        let totalDouble = Double(max(draft.totalYards, 1))
        let sorted = mix.sorted { lhs, rhs in lhs.value > rhs.value }

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(sorted, id: \.key) { element in
                    strokePill(stroke: element.key, yards: element.value, total: totalDouble)
                }
            }
        }
    }
    
    private func strokePill(stroke: StrokeType, yards: Int, total: Double) -> some View {
        let pct = Int(round((Double(yards) / total) * 100))
        return Text("\(stroke.displayName) \(pct)%")
            .font(AppFont.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                AppColor.surface.opacity(0.5),
                in: Capsule()
            )
            .foregroundStyle(.white.opacity(0.9))
    }

    // MARK: - Sections

    private var sectionsList: some View {
        VStack(spacing: 16) {
            ForEach(draft.sections.indices, id: \.self) { index in
                let section = draft.sections[index]
                sectionCard(index: index, section: section)
            }
        }
    }

    private func sectionCard(index: Int, section: PracticeSection) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(section.label)
                        .font(AppFont.cardTitle)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    // "Copy last set" button
                    if !section.sets.isEmpty {
                        Button {
                            copyLastSet(sectionIndex: index)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption2)
                                Text("Copy last")
                                    .font(AppFont.caption)
                            }
                            .foregroundStyle(AppColor.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColor.accent.opacity(0.1), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text("\(section.totalYards) yds")
                        .font(AppFont.caption.weight(.semibold))
                        .foregroundStyle(AppColor.accent)
                }

                Divider().background(AppColor.border)

                if section.sets.isEmpty {
                    // Empty state
                    VStack(spacing: 12) {
                        Text("No sets yet")
                            .font(AppFont.caption)
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Button {
                            openComposer(sectionIndex: index, setIndex: nil)
                        } label: {
                            Label("Add Set", systemImage: "plus.circle.fill")
                                .font(AppFont.body.weight(.semibold))
                                .foregroundStyle(Color.appAccent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    Color.appAccent.opacity(0.1),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    // Set rows
                    ForEach(section.sets.indices, id: \.self) { sIndex in
                        let set = section.sets[sIndex]
                        compactSetRow(sectionIndex: index, setIndex: sIndex, set: set)

                        if sIndex < section.sets.count - 1 {
                            Divider().background(AppColor.border.opacity(0.5))
                        }
                    }
                    
                    // Add more sets button
                    Button {
                        openComposer(sectionIndex: index, setIndex: nil)
                    } label: {
                        Label("Add Set", systemImage: "plus")
                            .font(AppFont.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                Color.white.opacity(0.05),
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func compactSetRow(sectionIndex: Int, setIndex: Int, set: PracticeSet) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header for repeated sets
            if set.repeatCount > 1 {
                Text("\(set.repeatCount) rounds of:")
                    .font(AppFont.caption.weight(.semibold))
                    .foregroundStyle(AppColor.accent)
                    .padding(.bottom, 2)
            }
            
            // Iterate through all lines
            ForEach(set.lines.indices, id: \.self) { lineIndex in
                let line = set.lines[lineIndex]
                
                VStack(alignment: .leading, spacing: 2) {
                    // Main line summary
                    Text(generateLineSummary(line))
                        .font(AppFont.body)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    // Optional notes line (if text is not empty and not already used in summary)
                    // The summary uses line.text if it's short/simple, but let's check logic
                    // If generateLineSummary uses line.text, we might duplicate it?
                    // Let's look at generateLineSummary logic below.
                    // It appends line.text at the end.
                    // So we probably don't need a separate notes line unless we want to split it?
                    // The original code had:
                    // if let line = set.lines.first, !line.text.isEmpty { Text(line.text) ... }
                    // But generateCompactSummary ALSO appended line.text.
                    // Let's stick to just the summary for now to avoid duplication, 
                    // or maybe only show separate notes if they are long?
                    // For now, let's trust generateLineSummary to include the text.
                }
                .padding(.leading, set.repeatCount > 1 ? 8 : 0) // Indent if part of a round
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            openComposer(sectionIndex: sectionIndex, setIndex: setIndex)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                draft.sections[sectionIndex].sets.remove(at: setIndex)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                duplicateSet(sectionIndex: sectionIndex, setIndex: setIndex)
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            .tint(Color.appAccent)
        }
    }
    
    private func generateLineSummary(_ line: PracticeLine) -> String {
        var parts: [String] = []
        
        // Reps × Distance
        if let reps = line.reps, let dist = line.distance {
            parts.append("\(reps) × \(dist)")
        } else if let dist = line.distance {
            parts.append("\(dist)")
        }
        
        // Stroke
        if let stroke = line.stroke {
            parts.append(stroke.displayName.lowercased())
        }
        
        // Interval
        if let interval = line.interval {
            let symbol = line.intervalType == .interval ? "@" : "rest"
            parts.append("\(symbol) \(interval)")
        }
        
        // Effort/equipment (from text)
        if !line.text.isEmpty {
            parts.append("– \(line.text)")
        } else if let effort = line.patterns.pace {
            parts.append("– \(effort.label.lowercased())")
        }
        
        return parts.joined(separator: " ")
    }
    
    // MARK: - Total Yardage Bar
    
    private var totalYardageBar: some View {
        GlassCard(cornerRadius: 0, padding: 0) {
            VStack(spacing: 0) {
                // Subtle top border for separation
                Rectangle()
                    .fill(AppColor.border.opacity(0.3))
                    .frame(height: 1)
                
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    
                    // Sections breakdown with separators
                    HStack(spacing: 0) {
                        let sections: [(String, String)] = [
                            ("WU", "Warmup"),
                            ("Pre", "Pre-Set"),
                            ("Main", "Main Set"),
                            ("Post", "Post-Set / Technique"),
                            ("CD", "Cooldown")
                        ]
                        
                        ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                            if let yards = sectionYards(section.1), yards > 0 {
                                if index > 0 && hasPreviousSection(before: index, in: sections) {
                                    Text("•")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white.opacity(0.3))
                                        .padding(.horizontal, 8)
                                }
                                
                                compactStat(section.0, yards: yards)
                            }
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
            }
        }
        .shadow(color: .black.opacity(0.2), radius: 10, y: -5)
    }
    
    private func hasPreviousSection(before index: Int, in sections: [(String, String)]) -> Bool {
        for i in 0..<index {
            if let yards = sectionYards(sections[i].1), yards > 0 {
                return true
            }
        }
        return false
    }
    
    private func sectionYards(_ label: String) -> Int? {
        draft.sections.first(where: { $0.label == label })?.totalYards
    }
    
    private func compactStat(_ label: String, yards: Int) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundStyle(.white.opacity(0.6))
            Text("\(yards)")
                .font(.system(size: 12, weight: .semibold, design: .default))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.95))
        }
    }

    // MARK: - Helpers

    private func openComposer(sectionIndex: Int, setIndex: Int?) {
        composerContext = SetComposerContext(sectionIndex: sectionIndex, setIndex: setIndex)
        showSetComposer = true
    }
    
    private func duplicateSet(sectionIndex: Int, setIndex: Int) {
        let original = draft.sections[sectionIndex].sets[setIndex]
        var duplicate = original
        duplicate.id = UUID()
        duplicate.lines = duplicate.lines.map { line in
            var newLine = line
            newLine.id = UUID()
            return newLine
        }
        draft.sections[sectionIndex].sets.insert(duplicate, at: setIndex + 1)
    }
    
    private func copyLastSet(sectionIndex: Int) {
        guard let lastSet = draft.sections[sectionIndex].sets.last else { return }
        
        // Open composer with the last set's data, but as a NEW set (setIndex: nil)
        // We need to pass the set data to the composer. 
        // The current SetComposerView takes an `existingSet` optional.
        // If we pass `existingSet`, it treats it as an EDIT.
        // We want to PRE-FILL but treat as NEW.
        
        // Since SetComposerView logic might be tied to "if existingSet != nil then edit mode",
        // we might need to adjust how we pass data or just duplicate it first then edit?
        // The requirement says: "Open the existing set composer sheet / editor using that set as the initial values... When the user taps Save... Append a new set".
        
        // If SetComposerView doesn't support "prefill but new", we can:
        // 1. Modify SetComposerView (avoid if possible per instructions "no model changes", but view changes ok?)
        // 2. Just duplicate the set into the model first, then open it for editing.
        
        // Let's try option 2 as it reuses existing logic perfectly:
        // "Duplicate last set" -> "Edit the new duplicate"
        
        duplicateSet(sectionIndex: sectionIndex, setIndex: draft.sections[sectionIndex].sets.count - 1)
        
        // Now open composer for the newly added set (which is at the end)
        let newIndex = draft.sections[sectionIndex].sets.count - 1
        openComposer(sectionIndex: sectionIndex, setIndex: newIndex)
    }

    private func save() {
        let missingTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let missingTag = draft.tag == nil
        
        if missingTitle && missingTag {
            showToast(message: "Please fill out title and practice tag")
            return
        } else if missingTitle {
            showToast(message: "Please fill out title")
            return
        } else if missingTag {
            showToast(message: "Please fill out practice tag")
            return
        }

        var final = draft
        final.lastEditedAt = Date()
        appData.addOrUpdateTemplate(final)
        dismiss()
    }
    
    private func showToast(message: String) {
        toastMessage = message
        withAnimation(.snappy) {
            showToast = true
        }
        
        // Auto hide
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.snappy) {
                showToast = false
            }
        }
    }
}
