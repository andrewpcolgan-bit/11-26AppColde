//
//  RecoverySuggestionsView.swift
//  SwimSetTracker
//

import SwiftUI

// Parsed from the backend's recoverySuggestions block
struct StretchItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let areas: [String]
    let description: String
    let dosage: String?
    let tip: String?
}

struct RecoverySuggestionsView: View {
    let practiceTitle: String
    let focusText: String
    let practiceTag: String?
    let suggestionsText: String

    @Environment(\.dismiss) private var dismiss

    private var stretches: [StretchItem] {
        parseSuggestions(suggestionsText)
    }

    private var totalMinutesEstimate: Int {
        // simple heuristic ~1.5 min per stretch
        let seconds = stretches.count * 90
        return max(1, Int(round(Double(seconds) / 60.0)))
    }

    private var focusAreasSummary: String {
        let allAreas = stretches
            .flatMap { $0.areas }
            .map { $0.lowercased() }

        let unique = Array(Set(allAreas)).sorted()
        if unique.isEmpty { return "full body" }
        if unique.count <= 3 { return unique.joined(separator: ", ") }
        return unique.prefix(3).joined(separator: ", ") + "…"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Session header card
                    // Header summary card
                    GlassCard {
                        VStack(alignment: .leading, spacing: 6) {
                            // Date line – small, all caps
                            Text(practiceTitle.uppercased())
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.7))
                                .tracking(1.2)

                            // Single main title – white
                            Text(focusText)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 8)
                    }

                    // Plan summary card
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Today’s Recovery Plan")
                                .font(.headline)
                                .foregroundStyle(.white)

                            Text("\(stretches.count) stretch\(stretches.count == 1 ? "" : "es") · ~\(totalMinutesEstimate) minutes total")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.85))

                            Text("Focus areas: \(focusAreasSummary)")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    }

                    // Stretch cards list
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Recovery & Stretches", systemImage: "figure.cooldown")
                            .font(.headline)
                            .foregroundStyle(.white)

                        if stretches.isEmpty {
                            GlassCard {
                                Text("Easy 5–10 minutes of light swimming and gentle stretching is recommended after this session.")
                                    .font(.footnote)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            ForEach(stretches) { stretch in
                                stretchCard(for: stretch)
                            }

                            Text("These are general suggestions. Always adjust volume and range based on how your body feels.")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.top, 4)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Post-Swim Recovery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Single Stretch Card

    @ViewBuilder
    private func stretchCard(for item: StretchItem) -> some View {
        GlassCard {
            HStack(spacing: 0) {
                // Accent bar
                Rectangle()
                    .fill(accentColor(for: item.areas))
                    .frame(width: 4)
                    .cornerRadius(2)
                    .padding(.vertical, 6)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)

                            if !item.areas.isEmpty {
                                Text(item.areas.joined(separator: " • "))
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }

                        Spacer()

                        if let dosage = item.dosage, !dosage.isEmpty {
                            Text(dosage)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.14), in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }

                    if !item.description.isEmpty {
                        Text(item.description)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let tip = item.tip, !tip.isEmpty {
                        Text(tip)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Parsing

    private func parseSuggestions(_ text: String) -> [StretchItem] {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return lines.compactMap { parseStretchLine($0) }
    }

    private func parseStretchLine(_ line: String) -> StretchItem? {
        // Strip leading bullet markers
        var core = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if core.hasPrefix("- ") {
            core.removeFirst(2)
        } else if core.hasPrefix("• ") {
            core.removeFirst(2)
        }

        // Split dosage after "•" if present
        let dosageParts = core.split(separator: "•", maxSplits: 1, omittingEmptySubsequences: true)
        let mainPart = dosageParts.first.map(String.init) ?? core
        let dosage = dosageParts.count > 1
            ? String(dosageParts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            : nil

        // Now split "Header: description"
        let headAndDesc = mainPart.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        let head = headAndDesc.first.map(String.init) ?? ""
        let rawDesc = headAndDesc.count > 1
            ? String(headAndDesc[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            : ""

        var title = head.trimmingCharacters(in: .whitespacesAndNewlines)
        var areas: [String] = []

        // Extract "(Areas...)" from head
        if let open = head.firstIndex(of: "("),
           let close = head.lastIndex(of: ")"),
           close > open {
            let titlePart = head[..<open]
            title = String(titlePart).trimmingCharacters(in: .whitespacesAndNewlines)

            let inside = head[head.index(after: open)..<close]
            let areaParts = inside
                .split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            areas = areaParts
        }

        let description = rawDesc
        if title.isEmpty && description.isEmpty {
            return nil
        }

        return StretchItem(
            title: title.isEmpty ? "Recovery Stretch" : title,
            areas: areas,
            description: description.isEmpty ? title : description,
            dosage: dosage,
            tip: nil
        )
    }

    private func accentColor(for areas: [String]) -> Color {
        let lower = areas.map { $0.lowercased() }

        if lower.contains(where: { $0.contains("shoulder") || $0.contains("lat") || $0.contains("pec") || $0.contains("chest") }) {
            return .teal
        }

        if lower.contains(where: { $0.contains("hip") || $0.contains("quad") || $0.contains("hamstring") || $0.contains("calf") || $0.contains("glute") }) {
            return .blue
        }

        if lower.contains(where: { $0.contains("core") || $0.contains("abs") || $0.contains("back") }) {
            return .purple
        }

        return .gray.opacity(0.7)
    }
}
