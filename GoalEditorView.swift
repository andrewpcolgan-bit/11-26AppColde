import SwiftUI

struct GoalEditorView: View {
    @EnvironmentObject var appData: AppData
    @Environment(\.dismiss) private var dismiss

    // Presets (updated)
    private let yardagePresets: [Int] = [20_000, 25_000, 30_000, 35_000]
    private let sessionPresets: [Int]  = [7, 8, 9, 10, 11, 12]
    private let trainingPhasePresets: [String] = [
        "Standard Week", "Meet Week", "Taper", "Peek week"
    ]

    // State
    @State private var yardsOn = true
    @State private var sessionsOn = true

    @State private var yardsTargetText: String = "20000"
    @State private var sessionsTargetText: String = "7"

    // Store Training Phase in WeeklyGoal.notes to avoid model changes
    @State private var selectedPhase: String? = "Standard Week"

    init() {}

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // MARK: Yardage
                    sectionCard {
                        SectionHeader(symbol: "ruler", title: "Yardage")
                        ToggleRow(isOn: $yardsOn, label: "Yardage goal")

                        if yardsOn {
                            PresetGrid(
                                options: yardagePresets.map { $0.formatted() },
                                selected: Binding<String>(
                                    get: { yardsTargetText },
                                    set: { yardsTargetText = $0.filter(\.isNumber) }
                                ),
                                onTap: { label in
                                    yardsTargetText = label.filter(\.isNumber)
                                },
                                columns: 4
                            )
                            NumberFieldRow(
                                prompt: "Custom yards",
                                text: $yardsTargetText,
                                keyboard: .numberPad,
                                suffix: "yds"
                            )
                        }
                    }

                    // MARK: Sessions
                    sectionCard {
                        SectionHeader(symbol: "calendar.badge.clock", title: "Sessions")
                        ToggleRow(isOn: $sessionsOn, label: "Sessions goal")

                        if sessionsOn {
                            PresetGrid(
                                options: sessionPresets.map(String.init),
                                selected: Binding<String>(
                                    get: { sessionsTargetText },
                                    set: { sessionsTargetText = $0.filter(\.isNumber) }
                                ),
                                onTap: { label in
                                    sessionsTargetText = label.filter(\.isNumber)
                                },
                                columns: 6
                            )
                            NumberFieldRow(
                                prompt: "Custom sessions",
                                text: $sessionsTargetText,
                                keyboard: .numberPad,
                                suffix: nil
                            )
                        }
                    }

                    // MARK: Training Phase
                    sectionCard {
                        SectionHeader(symbol: "bolt.heart", title: "Training Phase")
                        PhaseWrap(
                            options: trainingPhasePresets,
                            selected: selectedPhase ?? "",
                            onTap: { selectedPhase = $0 }
                        )
                        .padding(.top, 4)
                    }

                    // “This Week So Far” intentionally removed
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Set Weekly Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveGoal() }
                        .disabled(!yardsOn && !sessionsOn)
                }
            }
            .onAppear(perform: loadExistingGoal)
        }
    }

    // MARK: - Save / Load

    private func loadExistingGoal() {
        if let g = appData.weeklyGoal {
            if let y = g.yardsTarget {
                yardsOn = true
                yardsTargetText = "\(y)"
            } else {
                yardsOn = false
            }

            if let s = g.sessionsTarget {
                sessionsOn = true
                sessionsTargetText = "\(s)"
            } else {
                sessionsOn = false
            }

            if let phase = g.notes, !phase.isEmpty {
                selectedPhase = phase
            } else {
                selectedPhase = trainingPhasePresets.first
            }
        } else {
            yardsOn = true
            sessionsOn = true
            yardsTargetText = "20000"
            sessionsTargetText = "7"
            selectedPhase = trainingPhasePresets.first
        }
    }

    private func saveGoal() {
        let yards = yardsOn ? Int(yardsTargetText.filter(\.isNumber)) : nil
        let sessions = sessionsOn ? Int(sessionsTargetText.filter(\.isNumber)) : nil

        appData.weeklyGoal = WeeklyGoal(
            yardsTarget: yards,
            sessionsTarget: sessions,
            startDate: Date(),
            notes: selectedPhase // store phase here
        )
        dismiss()
    }
}

// MARK: - UI Building Blocks

private func sectionCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
    GlassCard {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
    }
}

private struct SectionHeader: View {
    let symbol: String
    let title: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(.teal)
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.bottom, 2)
    }
}

private struct ToggleRow: View {
    @Binding var isOn: Bool
    var label: String
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.vertical, 2)
    }
}

private struct NumberFieldRow: View {
    var prompt: String
    @Binding var text: String
    var keyboard: UIKeyboardType
    var suffix: String?

    var body: some View {
        HStack {
            TextField(prompt, text: $text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .foregroundStyle(.white)
            if let suffix {
                Text(suffix)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

/// Simple grid of equal-size chip buttons (single-select).
private struct PresetGrid: View {
    let options: [String]
    @Binding var selected: String
    var onTap: (String) -> Void
    var columns: Int = 4

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns), spacing: 8) {
            ForEach(options, id: \.self) { option in
                let raw = option.filter(\.isNumber) // so "20,000" matches "20000"
                let isSelected = (selected == raw) || (selected == option)
                Button {
                    onTap(option)
                } label: {
                    Text(option)
                        .font(.caption.weight(.semibold))
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(isSelected ? Color.teal.opacity(0.9) : Color.white.opacity(0.10))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Wrap-style chips using an adaptive grid (no reflection, compiles cleanly).
private struct PhaseWrap: View {
    let options: [String]
    let selected: String
    var onTap: (String) -> Void

    // Adaptive columns automatically wrap items based on width
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 120), spacing: 8)]
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(options, id: \.self) { opt in
                let active = (opt == selected)
                Button {
                    onTap(opt)
                } label: {
                    Text(opt)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(active ? Color.teal.opacity(0.9) : Color.white.opacity(0.10))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
