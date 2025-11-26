//
//  WeekView.swift
//  SwimSetTracker
//

import SwiftUI

struct WeekView: View {
    @EnvironmentObject var appData: AppData

    var body: some View {
        NavigationStack {
            List {
                Section {
                    headerCard
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        .listRowBackground(Color.clear)
                }
                thisWeeksPracticesSection()
                pastPracticesSection()
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("My Week")
        }
    }
}

// MARK: - Sections (split for type-checker sanity)
private extension WeekView {
    // Summary header

    @ViewBuilder
    func weekSummaryHeader() -> some View {
        if !appData.thisWeekPractices.isEmpty {
            let yards = appData.totalYards(in: currentWeekInterval())
            let sessions = appData.practiceCount(in: currentWeekInterval())
            let range = currentWeekRangeLabel() ?? "This Week"
            
            Text("\(range) • \(yards.formatted()) yds • \(sessions) session\(sessions == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    func dayHeader(for day: String) -> some View {
        HStack(spacing: 8) {
            Text(day)
                .font(.headline)
                .foregroundStyle(Color.appAccent)
            
            if isToday(day) {
                Text("Today")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.appAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.appAccent.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    // Practices for the current week, grouped by weekday
    @ViewBuilder
    func thisWeeksPracticesSection() -> some View {
        if appData.thisWeekPractices.isEmpty {
            Section {
                emptyStateCard
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .listRowBackground(Color.clear)
            }
        } else {
            ForEach(weekdayOrder, id: \.self) { day in
                if let practices = groupedPractices[day] {
                    Section {
                        ForEach(Array(practicesSorted(practices).enumerated()), id: \.element.id) { index, practice in
                            NavigationLink {
                                PracticeDetailScreen(practice: practice)
                                    .environmentObject(appData)
                            } label: {
                                WeeklyPracticeCard(practice: practice, index: index)
                            }
                            .buttonStyle(PracticeCardButtonStyle())
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .swipeActions {
                                Button(role: .destructive) {
                                    appData.deletePractice(practice)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        dayHeader(for: day)
                    }
                }
            }
        }
    }

    // Past practices launcher
    @ViewBuilder
    func pastPracticesSection() -> some View {
        Section {
            NavigationLink {
                PracticeListView()
                    .environmentObject(appData)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.headline)
                        .foregroundStyle(Color.appAccent)
                    
                    Text("Past Practices")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0.3), Color.black.opacity(0.25)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.cardStroke.opacity(0.6), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PracticeCardButtonStyle())
            .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 20, trailing: 16))
            .listRowBackground(Color.clear)
        }
    }
}

// MARK: - Header Card
private extension WeekView {
    var headerCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                // Title + subtitle
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Week")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)

                    if let label = currentWeekRangeLabel() {
                        Text(label)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }

                // Summary strip
                let yards = appData.totalYards(in: currentWeekInterval())
                let sessions = appData.practiceCount(in: currentWeekInterval())
                Text("This week: \(yards) yds · \(sessions) session\(sessions == 1 ? "" : "s")")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))

                Divider().background(.white.opacity(0.24))

                // Big numbers – yards + sessions
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(yards)")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("yds this week")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.78))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(sessions)")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("sessions")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.78))
                    }
                }

                Divider().background(.white.opacity(0.24))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Average Distance")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.72))
                        Text("\(averageDistance()) yds")
                            .font(.subheadline.bold())
                            .foregroundStyle(.teal)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Total Time")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.72))
                        Text(appData.formattedSwimTime(in: currentWeekInterval()))
                            .font(.subheadline.bold())
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding(16)
        }
    }

    var emptyStateCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.pool.swim")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))
            
            VStack(spacing: 6) {
                Text("No practices logged this week")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text("Log or build a practice from the Log tab to see it here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Grouping & helpers
private extension WeekView {
    /// Monday–Sunday ordering for display
    var weekdayOrder: [String] {
        var symbols = Calendar.current.weekdaySymbols
        if let sunday = symbols.first {
            symbols.removeFirst()
            symbols.append(sunday)
        }
        return symbols
    }

    var groupedPractices: [String: [AnalyzedPractice]] {
        Dictionary(grouping: appData.thisWeekPractices) { practice in
            if let date = ISO8601DateFormatter().date(from: practice.date) {
                let weekdayIndex = Calendar.current.component(.weekday, from: date) - 1
                let symbols = Calendar.current.weekdaySymbols
                return symbols[weekdayIndex]
            }
            return "Unknown Day"
        }
    }

    /// Sort practices within each day chronologically (uses timestamp, falls back to timeOfDay)
    func practicesSorted(_ practices: [AnalyzedPractice]) -> [AnalyzedPractice] {
        practices.sorted { a, b in
            let da = ISO8601DateFormatter().date(from: a.date)
            let db = ISO8601DateFormatter().date(from: b.date)
            switch (da, db) {
            case let (a?, b?): return a < b
            case (_?, nil):    return true
            case (nil, _?):    return false
            default:
                return timeOfDayRank(a.timeOfDay) < timeOfDayRank(b.timeOfDay)
            }
        }
    }

    func timeOfDayRank(_ label: String?) -> Int {
        switch (label ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "am", "morning": return 0
        case "pm", "afternoon": return 1
        case "evening": return 2
        default: return 3
        }
    }

    func currentWeekInterval() -> DateInterval? {
        WeeklyGoal.currentWeekInterval()
    }

    func averageDistance() -> Int {
        guard !appData.thisWeekPractices.isEmpty else { return 0 }
        let total = appData.thisWeekPractices.map(\.distanceYards).reduce(0, +)
        return total / appData.thisWeekPractices.count
    }

    func currentWeekRangeLabel() -> String? {
        guard let interval = currentWeekInterval() else { return nil }
        let calendar = Calendar.current
        let start = interval.start
        guard let end = calendar.date(byAdding: .day, value: 6, to: start) else { return nil }

        let f = DateFormatter()
        f.dateFormat = "MMM d"
        let startStr = f.string(from: start)
        let endStr = f.string(from: end)
        return "Week of \(startStr) – \(endStr)"
    }
    
    func isToday(_ dayName: String) -> Bool {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f.string(from: Date()) == dayName
    }
}

// MARK: - WeeklyPracticeCard (kept local so it's always in scope)
struct WeeklyPracticeCard: View {
    let practice: AnalyzedPractice
    var index: Int = 0
    
    @State private var isAppearing = false

    // Layout constants
    private let columnGap: CGFloat = 12
    private let rightRailWidth: CGFloat = 112

    // Colors
    private let primaryText = Color.white
    private let secondaryText = Color.white.opacity(0.85)
    private let mutedText = Color.white.opacity(0.68)
    private let hairline = Color.white.opacity(0.26)
    private let chipFill = Color.white.opacity(0.20)
    private let chipStroke = Color.white.opacity(0.30)

    var body: some View {

            VStack(alignment: .leading, spacing: 10) {
                
                // ── HEADER ROW: Title + Date only (full width)
                HStack(alignment: .firstTextBaseline) {
                    Text(primaryTitleLine(for: practice))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                
                // ── TWO-COLUMN LAYOUT: Left details + Right yardage pillar
                HStack(alignment: .center, spacing: columnGap) {
                    
                    // LEFT COLUMN: All textual details
                    VStack(alignment: .leading, spacing: 6) {
                        
                        // Primary type label
                        Text(practiceTagText(for: practice))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(secondaryText)
                            .lineLimit(1)
                        
                        // Pill row (AM/PM + Type chips)
                        HStack(spacing: 8) {
                            if let ampm = amPmLabel(for: practice) {
                                pill(text: ampm)
                            }
                            if let type = typeChipText(for: practice) {
                                pill(text: type)
                            }
                        }
                        
                        // Time row
                        if let timeRange = timeRangeText(for: practice) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                    .foregroundStyle(mutedText)
                                Text(timeRange)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(mutedText)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer(minLength: 12)
                    
                    // RIGHT COLUMN: Yardage pillar (vertically centered)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(practice.distanceYards.formatted(.number.grouping(.automatic)))
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(primaryText)
                            .monospacedDigit()
                        
                        Text("yds")
                            .font(.caption)
                            .foregroundStyle(mutedText)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(mutedText)
                    }
                }
                
                // ── SECTION BREAKDOWN: Full width at bottom
                if let line = compactSectionLine(from: practice.sectionYards) {
                    Text(line)
                        .font(.caption2)
                        .foregroundStyle(mutedText)
                        .lineLimit(2)
                }
            }

            .padding(14)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.45), Color.black.opacity(0.35)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.cardStroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)

        .opacity(isAppearing ? 1 : 0)
        .offset(y: isAppearing ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.05)) {
                isAppearing = true
            }
        }
    }
}

struct PracticeCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { pressed in
                if pressed {
                    Haptics.lightImpact()
                }
            }
    }
}

// MARK: - WeeklyPracticeCard helpers
private extension WeeklyPracticeCard {
    func primaryTitleLine(for p: AnalyzedPractice) -> String {
        let weekday = weekdayName(for: p) ?? "Practice"
        let ampm = amPmLabel(for: p)
        let md = monthDay(for: p) ?? ""
        if let ampm {
            return "\(weekday) \(ampm) practice · \(md)"
        } else {
            return "\(weekday) practice · \(md)"
        }
    }

    func weekdayName(for p: AnalyzedPractice) -> String? {
        guard let date = ISO8601DateFormatter().date(from: p.date) else { return nil }
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f.string(from: date)
    }

    func monthDay(for p: AnalyzedPractice) -> String? {
        guard let date = ISO8601DateFormatter().date(from: p.date) else { return nil }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    func pill(text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.white.opacity(0.85))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(chipFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(chipStroke, lineWidth: 0.5)
                    )
            )
    }

    func amPmLabel(for p: AnalyzedPractice) -> String? {
        let raw = (p.timeOfDay ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        if raw.hasSuffix("AM") || raw == "AM" || raw == "MORNING" {
            return "AM"
        }
        if raw.hasSuffix("PM") || raw == "PM" || raw == "AFTERNOON" || raw == "EVENING" {
            return "PM"
        }

        if let date = ISO8601DateFormatter().date(from: p.date) {
            let hour = Calendar.current.component(.hour, from: date)
            return hour < 12 ? "AM" : "PM"
        }
        return nil
    }

    func typeChipText(for p: AnalyzedPractice) -> String? {
        let source = (p.practiceTag ?? "") + " " + p.aiSummary
        let s = source.lowercased()

        if s.contains("im") { return "IM" }
        if s.contains("mid") && s.contains("distance") { return "Mid-Distance" }
        if s.contains("sprint") || s.contains("race-pace") || s.contains("race pace") { return "Race-Pace" }
        if s.contains("threshold") { return "Threshold" }
        if s.contains("aerobic") { return "Aerobic" }
        if s.contains("kick") { return "Kick" }
        if s.contains("pull") { return "Pull" }
        return nil
    }

    func compactSectionLine(from dict: [String: Int]) -> String? {
        let order = ["Warmup", "Preset", "Main Set", "Post-Set", "Cooldown"]
        let abbreviations: [String: String] = [
            "Warmup": "Warmup",
            "Preset": "Preset",
            "Main Set": "Main",
            "Post-Set": "Post",
            "Cooldown": "CD"
        ]

        var parts: [String] = []
        for key in order {
            if let v = matchingSectionValue(in: dict, for: key), v > 0 {
                let label = abbreviations[key] ?? key
                parts.append("\(label) \(v.formatted(.number.grouping(.automatic)))")
            }
        }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " • ")
    }

    func practiceTagText(for p: AnalyzedPractice) -> String {
        if let tag = p.practiceTag?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !tag.isEmpty,
           !tag.lowercased().hasPrefix("no summary") {
            return tag
        }
        return "Unlabeled Session"
    }

    func matchingSectionValue(in dict: [String: Int], for key: String) -> Int? {
        dict.first(where: { dictKey, _ in
            dictKey.compare(key, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame ||
            dictKey.replacingOccurrences(of: "-", with: " ")
                .compare(key.replacingOccurrences(of: "-", with: " "),
                         options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        })?.value
    }
    
    func timeRangeText(for p: AnalyzedPractice) -> String? {
        guard let date = ISO8601DateFormatter().date(from: p.date),
              p.durationMinutes > 0 else { return nil }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm"
        
        let startTime = timeFormatter.string(from: date)
        
        guard let endDate = Calendar.current.date(byAdding: .minute, value: p.durationMinutes, to: date) else {
            return nil
        }
        
        let endTime = timeFormatter.string(from: endDate)
        
        return "\(startTime)-\(endTime)"
    }
}
