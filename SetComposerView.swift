import SwiftUI

struct SetComposerView: View {
    let sectionLabel: String
    let existingSet: PracticeSet?
    let onSave: (PracticeSet) -> Void
    let onDelete: (() -> Void)?
    
    @Environment(\.dismiss) var dismiss
    
    // Set components state
    @State private var reps: Int = 4
    @State private var distance: Int = 50
    @State private var selectedStroke: StrokeType? = .freestyle
    @State private var selectedMode: StrokeType? = nil
    @State private var intervalKind: IntervalKind = .sendoff
    @State private var intervalSeconds: Int? = 50
    @State private var effort: PacePattern? = nil
    @State private var equipment: Set<String> = []
    @State private var notes: String = ""
    @State private var customPreview: String = ""
    @State private var isEditingPreview: Bool = false
    
    // Common presets
    private let repsPresets = [1, 2, 3, 4, 6, 8, 10, 12]
    private let distancePresets = [25, 50, 75, 100, 150, 200, 300, 400]
    private let equipmentOptions = ["Fins", "Paddles", "Snorkel", "Pull Buoy", "Board"]
    
    init(sectionLabel: String, existingSet: PracticeSet? = nil, onSave: @escaping (PracticeSet) -> Void, onDelete: (() -> Void)? = nil) {
        self.sectionLabel = sectionLabel
        self.existingSet = existingSet
        self.onSave = onSave
        self.onDelete = onDelete
        
        // Pre-populate from existing set if editing
        if let set = existingSet, let line = set.lines.first {
            _reps = State(initialValue: line.reps ?? 4)
            _distance = State(initialValue: line.distance ?? 50)
            
            // Parse stroke vs mode
            if let strokeType = line.stroke {
                if strokeType.isStroke {
                    _selectedStroke = State(initialValue: strokeType)
                } else if strokeType.isMode {
                    _selectedMode = State(initialValue: strokeType)
                }
            }
            
            // NEW: Load mode from the mode field
            if let modeType = line.mode {
                _selectedMode = State(initialValue: modeType)
            }
            
            _intervalKind = State(initialValue: line.intervalKind)
            _intervalSeconds = State(initialValue: line.intervalSeconds)
            _effort = State(initialValue: line.patterns.pace)
            
            // Parse equipment from text if present
            let text = line.text
            var equip: Set<String> = []
            for option in equipmentOptions {
                if text.lowercased().contains(option.lowercased()) {
                    equip.insert(option)
                }
            }
            _equipment = State(initialValue: equip)
            
            // Extract notes (everything after equipment)
            _notes = State(initialValue: extractNotes(from: text))
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Live Preview
                        livePreview
                        
                        // Input Controls
                        VStack(spacing: 20) {
                            repsSection
                            distanceSection
                            strokeSection
                            intervalSection
                            effortSection
                            equipmentSection
                            notesSection
                            
                            if existingSet != nil {
                                Button(role: .destructive) {
                                    onDelete?()
                                    dismiss()
                                } label: {
                                    Text("Delete Set")
                                        .font(AppFont.body.weight(.semibold))
                                        .foregroundStyle(.red)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(existingSet == nil ? "Add Set" : "Edit Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingSet == nil ? "Add to \(sectionLabel)" : "Save") {
                        saveSet()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Live Preview
    
    private var livePreview: some View {
        VStack(spacing: 8) {
            Text("PREVIEW")
                .font(AppFont.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.6))
            
            if isEditingPreview {
                // Editable preview
                TextField("Type custom set description", text: $customPreview)
                    .font(AppFont.body.weight(.medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColor.accent.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColor.accent.opacity(0.5), lineWidth: 2)
                            )
                    )
                    .padding(.horizontal, 20)
                    .overlay(
                        Button {
                            isEditingPreview = false
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColor.accent)
                                .font(.title2)
                        }
                        .padding(.trailing, 30),
                        alignment: .trailing
                    )
            } else {
                // Display-only preview with tap to edit
                Button {
                    customPreview = generatePreview()
                    isEditingPreview = true
                } label: {
                    Text(customPreview.isEmpty ? generatePreview() : customPreview)
                        .font(AppFont.body.weight(.medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColor.accent.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColor.accent.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .overlay(
                            Image(systemName: "pencil")
                                .foregroundStyle(.white.opacity(0.4))
                                .font(.caption)
                                .padding(.trailing, 12),
                            alignment: .trailing
                        )
                }
                .padding(.horizontal, 20)
            }
            
            if !isEditingPreview {
                Text("Tap to edit preview")
                    .font(AppFont.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.top, 12)
    }
    
    private func generatePreview() -> String {
        var parts: [String] = []
        
        // Reps × Distance
        parts.append("\(reps) × \(distance)")
        
        // Stroke + Mode (both optional)
        var strokeModeParts: [String] = []
        if let stroke = selectedStroke {
            strokeModeParts.append(stroke.displayName.lowercased())
        }
        if let mode = selectedMode {
            strokeModeParts.append(mode.displayName.lowercased())
        }
        if !strokeModeParts.isEmpty {
            parts.append(strokeModeParts.joined(separator: " "))
        }
        
        // Interval (optional)
        if intervalKind != .none, let seconds = intervalSeconds {
            let timeStr = IntervalFormatter.format(seconds: seconds)
            switch intervalKind {
            case .sendoff:
                parts.append("@ \(timeStr)")
            case .rest:
                parts.append("\(timeStr) rest")
            case .none:
                break
            }
        }
        
        // Effort
        if let effort = effort {
            parts.append("– \(effort.label.lowercased())")
        }
        
        // Equipment
        if !equipment.isEmpty {
            parts.append(equipment.sorted().joined(separator: ", ").lowercased())
        }
        
        return parts.joined(separator: " ")
    }
    
    // MARK: - Reps Section
    
    private var repsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reps")
                .font(AppFont.captionBold)
                .foregroundStyle(.white.opacity(0.6))
            
            HStack(spacing: 0) {
                Button {
                    if reps > 1 { reps -= 1 }
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(repsPresets, id: \.self) { preset in
                            Button {
                                reps = preset
                            } label: {
                                Text("\(preset)")
                                    .font(AppFont.body.weight(reps == preset ? .bold : .medium))
                                    .foregroundStyle(reps == preset ? Color.black : .white)
                                    .frame(minWidth: 44, minHeight: 44)
                                    .background(reps == preset ? AppColor.accent : Color.white.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
                
                Button {
                    reps += 1
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 44, height: 44)
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
    
    // MARK: - Distance Section
    
    private var distanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Distance (yards)")
                .font(AppFont.captionBold)
                .foregroundStyle(.white.opacity(0.6))
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 8) {
                ForEach(distancePresets, id: \.self) { preset in
                    Button {
                        distance = preset
                    } label: {
                        Text("\(preset)")
                            .font(AppFont.body.weight(distance == preset ? .bold : .medium))
                            .foregroundStyle(distance == preset ? Color.black : .white)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(distance == preset ? AppColor.accent : Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(distance == preset ? AppColor.accent.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Stroke Section
    
    private var strokeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Strokes Row
            VStack(alignment: .leading, spacing: 8) {
                Text("Stroke (Optional)")
                    .font(AppFont.captionBold)
                    .foregroundStyle(.white.opacity(0.6))
                
                FlowLayout(spacing: 8) {
                    ForEach([StrokeType.freestyle, .backstroke, .breaststroke, .butterfly, .im, .choice], id: \.self) { strokeType in
                        strokeChip(for: strokeType)
                    }
                }
            }
            
            // Modes Row
            VStack(alignment: .leading, spacing: 8) {
                Text("Mode (Optional)")
                    .font(AppFont.captionBold)
                    .foregroundStyle(.white.opacity(0.6))
                
                FlowLayout(spacing: 8) {
                    ForEach([StrokeType.swim, .kick, .pull, .drill, .scull, .technique], id: \.self) { strokeType in
                        strokeChip(for: strokeType)
                    }
                }
            }
        }
    }
    
    private func strokeChip(for strokeType: StrokeType) -> some View {
        let isSelected: Bool
        if strokeType.isStroke {
            isSelected = selectedStroke == strokeType
        } else {
            isSelected = selectedMode == strokeType
        }
        
        return Button {
            // Toggle within the appropriate category
            if strokeType.isStroke {
                if selectedStroke == strokeType {
                    selectedStroke = nil
                } else {
                    selectedStroke = strokeType
                }
            } else if strokeType.isMode {
                if selectedMode == strokeType {
                    selectedMode = nil
                } else {
                    selectedMode = strokeType
                }
            }
        } label: {
            Text(strokeType.displayName)
                .font(AppFont.caption.weight(isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? Color.black : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? AppColor.accent : Color.white.opacity(0.05))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? AppColor.accent.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Interval Section
    
    private var intervalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Interval")
                .font(AppFont.captionBold)
                .foregroundStyle(.white.opacity(0.6))
            
            Picker("Interval Kind", selection: $intervalKind) {
                ForEach(IntervalKind.allCases) { kind in
                    Text(kind.label).tag(kind)
                }
            }
            .pickerStyle(.segmented)
            
            if intervalKind != .none {
                VStack(spacing: 12) {
                    recentIntervalsRow
                    IntervalKeypad(seconds: $intervalSeconds)
                }
            }
        }
    }
    
    private var recentIntervalsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent")
                .font(AppFont.caption)
                .foregroundStyle(.white.opacity(0.5))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach([30, 40, 45, 50, 60, 70, 80, 90], id: \.self) { seconds in
                        Button {
                            intervalSeconds = seconds
                        } label: {
                            Text(IntervalFormatter.format(seconds: seconds))
                                .font(AppFont.caption.weight(.medium))
                                .foregroundStyle(intervalSeconds == seconds ? Color.black : .white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(intervalSeconds == seconds ? AppColor.accent : Color.white.opacity(0.05))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(intervalSeconds == seconds ? AppColor.accent.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Effort Section
    
    private var effortSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Effort (Optional)")
                .font(AppFont.captionBold)
                .foregroundStyle(.white.opacity(0.6))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach([PacePattern.easy, .cruise, .moderate, .fast, .sprint, .threshold], id: \.self) { pace in
                        Button {
                            effort = (effort == pace) ? nil : pace
                        } label: {
                            Text(pace.label)
                                .font(AppFont.body.weight(effort == pace ? .bold : .medium))
                                .foregroundStyle(effort == pace ? Color.black : .white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(effort == pace ? AppColor.accent : Color.white.opacity(0.05))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(effort == pace ? AppColor.accent.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Equipment Section
    
    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Equipment (Optional)")
                .font(AppFont.captionBold)
                .foregroundStyle(.white.opacity(0.6))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(equipmentOptions, id: \.self) { item in
                        Button {
                            if equipment.contains(item) {
                                equipment.remove(item)
                            } else {
                                equipment.insert(item)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                if equipment.contains(item) {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                }
                                Text(item)
                            }
                            .font(AppFont.body.weight(equipment.contains(item) ? .bold : .medium))
                            .foregroundStyle(equipment.contains(item) ? Color.black : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(equipment.contains(item) ? AppColor.accent : Color.white.opacity(0.05))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(equipment.contains(item) ? AppColor.accent.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes (Optional)")
                .font(AppFont.captionBold)
                .foregroundStyle(.white.opacity(0.6))
            
            TextField("e.g., build 1-4, no breath last 15", text: $notes)
                .font(AppFont.body)
                .foregroundStyle(.white)
                .padding(12)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Save Logic
    
    private func saveSet() {
        // Determine final text - use custom preview if edited, otherwise generate
        let finalText: String
        if !customPreview.isEmpty {
            // User typed custom preview - use it directly
            finalText = customPreview
        } else {
            // Build text from mode, effort, and equipment
            var textParts: [String] = []
            
            // Add mode to text if selected
            if let mode = selectedMode {
                textParts.append(mode.displayName.lowercased())
            }
            
            if let effort = effort {
                textParts.append(effort.label.lowercased())
            }
            
            if !equipment.isEmpty {
                textParts.append(equipment.sorted().joined(separator: ", ").lowercased())
            }
            
            if !notes.isEmpty {
                textParts.append(notes)
            }
            
            finalText = textParts.joined(separator: " – ")
        }
        
        let legacyInterval = intervalSeconds.map { IntervalFormatter.format(seconds: $0) }
        
        // Create practice line - use selectedStroke for the stroke field
        let line = PracticeLine(
            id: existingSet?.lines.first?.id ?? UUID(),
            reps: reps,
            distance: distance,
            stroke: selectedStroke, // Primary stroke (Free, Back, Breast, etc.)
            mode: selectedMode, // NEW: Mode (Drill, Kick, Pull, Swim, etc.)
            interval: intervalKind != .none ? legacyInterval : nil,
            intervalType: intervalKind == .rest ? .rest : .interval,
            intervalSeconds: intervalSeconds,
            intervalKind: intervalKind,
            text: finalText, // Mode + effort + equipment
            yardageOverride: nil,
            patterns: SetPatterns(pace: effort, stroke: nil, focus: [])
        )
        
        // Create practice set
        let set = PracticeSet(
            id: existingSet?.id ?? UUID(),
            title: nil,
            repeatCount: 1,
            lines: [line]
        )
        
        onSave(set)
        dismiss()
    }
    
    // MARK: - Helpers
    
    private func extractNotes(from text: String) -> String {
        var remaining = text
        
        // Remove equipment
        for item in equipmentOptions {
            remaining = remaining.replacingOccurrences(of: item.lowercased(), with: "", options: .caseInsensitive)
        }
        
        // Remove effort if present
        if let effort = effort {
            remaining = remaining.replacingOccurrences(of: effort.label.lowercased(), with: "", options: .caseInsensitive)
        }
        
        // Clean up separators
        remaining = remaining.replacingOccurrences(of: " – ", with: " ")
        remaining = remaining.trimmingCharacters(in: .whitespacesAndNewlines)
        remaining = remaining.trimmingCharacters(in: CharacterSet(charactersIn: "–,"))
        remaining = remaining.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return remaining
    }
}
